import ArgumentParser
import AsyncAlgorithms
import Foundation
import Hummingbird
import HummingbirdWebSocket
import HummingbirdWSCompression
import Logging
import ServiceLifecycle

// snippet.ConnectionManager
struct ConnectionManager: Service {

    // ...
    // snippet.hide
    typealias OutputStream = AsyncChannel<WebSocketOutboundWriter.OutboundFrame>

    struct Connection {
        let name: String
        let inbound: WebSocketInboundStream
        let outbound: OutputStream
    }

    actor OutboundConnections {
        
        var outboundWriters: [String: OutputStream]

        init() {
            self.outboundWriters = [:]
        }
        
        func send(_ output: String) async {
            for outbound in outboundWriters.values {
                await outbound.send(.text(output))
            }
        }
        
        func add(name: String, outbound: OutputStream) async {
            outboundWriters[name] = outbound
            await send("\(name) joined")
        }

        func remove(name: String) async {
            outboundWriters[name] = nil
            await send("\(name) left")
        }
    }
    // snippet.show

    let connectionStream: AsyncStream<Connection>
    let connectionContinuation: AsyncStream<Connection>.Continuation
    let logger: Logger

    init(logger: Logger) {
        let stream = AsyncStream<Connection>.makeStream()
        self.connectionStream = stream.stream
        self.connectionContinuation = stream.continuation
        self.logger = logger
    }

    func run() async {
        await withGracefulShutdownHandler {
            await withDiscardingTaskGroup { group in
                let outboundCounnections = OutboundConnections()
                // 1.
                for await connection in connectionStream {
                    group.addTask {
                        logger.info("add connection", metadata: [
                            "name": .string(connection.name)
                        ])
                        // 2.
                        await outboundCounnections.add(
                            name: connection.name,
                            outbound: connection.outbound
                        )

                        do {
                            // 3.
                            for try await input in connection.inbound.messages(
                                maxSize: 1_000_000
                            ) {
                                guard case .text(let text) = input else {
                                    continue
                                }
                                let output = "[\(connection.name)]: \(text)"
                                logger.debug("Output", metadata: [
                                    "message": .string(output)
                                ])
                                // 4.
                                await outboundCounnections.send(output)
                            }
                        } catch {}

                        logger.info("remove connection", metadata: [
                            "name": .string(connection.name)
                        ])
                        // 5.
                        await outboundCounnections.remove(name: connection.name)
                        connection.outbound.finish()
                    }
                }
                group.cancelAll()
            }
        } onGracefulShutdown: {
            connectionContinuation.finish()
        }
    }

    // snippet.hide
    
    func addUser(
        name: String,
        inbound: WebSocketInboundStream,
        outbound: WebSocketOutboundWriter
    ) -> OutputStream {
        let outputStream = OutputStream()
        let connection = Connection(
            name: name,
            inbound: inbound,
            outbound: outputStream
        )
        connectionContinuation.yield(connection)
        return outputStream
    }

    // snippet.show
}
// snippet.end

// snippet.buildApplication
func buildApplication(
    _ arguments: some AppArguments
) async throws -> some ApplicationProtocol {
    var logger = Logger(label: "WebSocketChat")
    logger.logLevel = .trace

    // 1.
    let router = Router()
    router.middlewares.add(LogRequestsMiddleware(.debug))
    router.middlewares.add(FileMiddleware(logger: logger))

    // 2.
    let connectionManager = ConnectionManager(logger: logger)
    // 3.
    let wsRouter = Router(context: BasicWebSocketRequestContext.self)
    wsRouter.middlewares.add(LogRequestsMiddleware(.debug))
    // 4.
    wsRouter.ws("chat") { request, _ in
        guard request.uri.queryParameters["username"] != nil else {
            return .dontUpgrade
        }
        return .upgrade([:])
    // 5.
    } onUpgrade: { inbound, outbound, context in
        guard let name = context.request.uri.queryParameters["username"] else {
            return
        }
        let outputStream = connectionManager.addUser(
            name: String(name),
            inbound: inbound,
            outbound: outbound
        )
        for try await output in outputStream {
            try await outbound.write(output)
        }
    }

    // ...
    // snippet.hide
    var app = Application(
        router: router,
        server: .http1WebSocketUpgrade(
            webSocketRouter: wsRouter,
            configuration: .init(extensions: [.perMessageDeflate()])
        ),
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port)
        ),
        logger: logger
    )
    // 7.
    app.addServices(connectionManager)
    return app
    // snippet.show
}
// snippet.end

// snippet.entrypoint
// 1.
protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
}

// 2.
@main
struct HummingbirdArguments: AppArguments, AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8080

    func run() async throws {
        // 3.
        let app = try await buildApplication(self)
        try await app.runService()
    }
}
// snippet.end
