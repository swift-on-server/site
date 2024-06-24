import ArgumentParser
import AsyncAlgorithms
import Foundation
import Hummingbird
import HummingbirdWebSocket
import HummingbirdWSCompression
import Logging
import ServiceLifecycle

// snippet.hide
struct ConnectionManager: Service {

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

    let connectionStream: AsyncStream<Connection>
    let connectionContinuation: AsyncStream<Connection>.Continuation
    let logger: Logger

    init(logger: Logger) {
        let stream = AsyncStream<Connection>.makeStream()
        self.connectionStream = stream.stream
        self.connectionContinuation = stream.continuation
        self.logger = logger
    }

    func run() async {}
    
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
}

protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
}
// snippet.show
func buildApplication(
    _ arguments: some AppArguments
) async throws -> some ApplicationProtocol {
    // snippet.hide
    var logger = Logger(label: "WebSocketChat")
    logger.logLevel = .trace
    let router = Router()
    router.middlewares.add(LogRequestsMiddleware(.debug))
    router.middlewares.add(FileMiddleware(logger: logger))
    let wsRouter = Router(context: BasicWebSocketRequestContext.self)
    // snippet.show
    // ... 
    let connectionManager = ConnectionManager(logger: logger)
    // ...
    // 1.
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
    // 2.
    app.addServices(connectionManager)
    return app
}
