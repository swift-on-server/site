import Foundation
import Hummingbird
import HummingbirdWebSocket
import HummingbirdWSCompression
import Logging
import ServiceLifecycle

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

    // 6.
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
}
