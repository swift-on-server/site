# WebSocket tutorial using Swift and Hummingbird

In this article, you will learn about WebSockets and how to use them with the Hummingbird framework in a straightforward, easy-to-follow manner. The first part will give a clear understanding of what the WebSocket protocol is. After that, a hands-on example will be created using the Hummingbird WebSocket library, showing how to use this technology effectively.

## What is a WebSocket?

The WebSocket protocol is a communication protocol that enables two-way, real-time interaction between a client and a server. It is designed to work over a single, long-lived connection, which significantly reduces the overhead compared to traditional HTTP request-response cycles. This protocol starts with a WebSocket handshake, which uses HTTP to establish the connection, and then upgrades it to the WebSocket protocol, allowing both the client and server to send and receive messages asynchronously.

WebSockets are particularly useful for applications that require low latency and high-frequency updates, such as online gaming, chat applications, and live data feeds. The protocol supports full-duplex communication, meaning data can be sent and received simultaneously, which enhances performance and responsiveness. This efficient data transfer method helps in creating more interactive applications, providing a smoother user experience.

## WebSockets vs long polling vs HTTP streaming, and server-sent events

Various methods have been used to achieve real-time capabilities by allowing data to be sent directly from the server to clients, but none have been as efficient as WebSockets. Techniques like HTTP polling, HTTP streaming, Comet, and SSE (server-sent events) all have their drawbacks. Let’s explore how these methods differ.

### Long polling (HTTP polling)

Long polling (HTTP polling) was one of the first methods to address real-time data fetching. It involved the client frequently sending requests to the server at regular intervals. Long polling improved on this by having the server hold the request open until there’s new data or a timeout occurs. Once data is available, the server responds, and the client immediately sends a new request. However, long polling had several issues, including header overhead, latency, timeouts, and caching problems.

### HTTP streaming

HTTP streaming reduces network latency by keeping the initial request open indefinitely. Unlike long polling, the server does not close the connection after sending data; it keeps it open to send new updates whenever there is a change. The first few steps of HTTP streaming are similar to long polling, but the key difference is that the connection remains active. This method allows continuous data updates and can be implemented using low-level streaming APIs.

### SSE - Server-sent events

Server-sent events (SSE) allow the server to push data to the client, similar to HTTP streaming. SSE is a standardized version of HTTP streaming and includes a built-in browser API. However, SSE is not suitable for applications like chat or gaming that require two-way communication since it only allows one-way data flow from the server to the client. SSE uses traditional HTTP and has limitations on the number of open connections.

## Why to use WebSockets?

Compared to WebSockets, these methods are less efficient and often seem like workarounds to make a request-reply protocol appear full-duplex. WebSockets are designed to replace existing bidirectional communication methods, as the previously mentioned methods are neither reliable nor efficient for full-duplex real-time communication. WebSockets are similar to SSE but excel in enabling messages to be sent from the client to the server. Connection restrictions are no longer an issue because data is transmitted over a single TCP socket connection.

### Security (WSS)

WebSocket (WS) uses a plain-text HTTP protocol, making it less secure and easy to intercept. WebSocket Secure (WSS), like HTTPS, encrypts data with SSL/TLS, preventing interception and increasing security. WSS protects against man-in-the-middle attacks but does not offer cross-origin or application-level security. Developers should add URL origin checks and strong authentication. 

## How to use WebSockets to build a real-time chat application?


```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "websocket-chat",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "App", targets: ["App"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0-beta.5"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.0.0-beta.2"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
                .product(name: "HummingbirdWSCompression", package: "hummingbird-websocket"),
            ]
        )
    ]
)
```


```swift
import ArgumentParser
import Hummingbird

protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
}

@main
struct HummingbirdArguments: AppArguments, AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8080

    func run() async throws {
        let app = try await buildApplication(self)
        try await app.runService()
    }
}

```


```swift
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

    let router = Router()
    router.middlewares.add(LogRequestsMiddleware(.debug))
    router.middlewares.add(FileMiddleware(logger: logger))

    let connectionManager = ConnectionManager(logger: logger)
    let wsRouter = Router(context: BasicWebSocketRequestContext.self)
    wsRouter.middlewares.add(LogRequestsMiddleware(.debug))
    wsRouter.ws("chat") { request, _ in
        guard request.uri.queryParameters["username"] != nil else {
            return .dontUpgrade
        }
        return .upgrade([:])
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
    app.addServices(connectionManager)
    return app
}
```

```swift
import AsyncAlgorithms
import Hummingbird
import HummingbirdWebSocket
import Logging
import NIOConcurrencyHelpers
import ServiceLifecycle

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

    func run() async {
        await withGracefulShutdownHandler {
            await withDiscardingTaskGroup { group in
                let outboundCounnections = OutboundConnections()
                for await connection in connectionStream {
                    group.addTask {
                        logger.info("add connection", metadata: [
                            "name": .string(connection.name)
                        ])
                        await outboundCounnections.add(
                            name: connection.name,
                            outbound: connection.outbound
                        )

                        do {
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
                                await outboundCounnections.send(output)
                            }
                        } catch {}

                        logger.info("remove connection", metadata: [
                            "name": .string(connection.name)
                        ])
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
```

```html
<!DOCTYPE html>
<head>
    <meta charset="utf-8" />
    <title>WebSocket Chat</title>
    <script language="javascript" type="text/javascript">

        var wsUri = "ws://localhost:8080/chat";
        var connected = false;
        var input;
        var output;

        function init() {
            input = document.getElementById("input");
            output = document.getElementById("output");
            input.value = ""
        }

        function openWebSocket(uri) {
            websocket = new WebSocket(uri);
            websocket.onopen = function(evt) { onOpen(evt) };
            websocket.onclose = function(evt) { onClose(evt) };
            websocket.onmessage = function(evt) { onMessage(evt) };
            websocket.onerror = function(evt) { onError(evt) };
        }

        function onOpen(evt) {
          
        }

        function onClose(evt) {
            writeToScreen("DISCONNECTED");
            connected = false
            let enterName = document.getElementById("enter_name")
            enterName.style.display = 'block'
        }

        function onMessage(evt) {
            writeToScreen('<span style="color: blue;">' + evt.data + '</span>');
        }

        function onError(evt) {
            writeToScreen('<span style="color: red;">ERROR:</span> ' + evt);
        }

        function doSend(message) {
            websocket.send(message);
        }

        function writeToScreen(message) {
            var pre = document.createElement("p");
            pre.style.wordWrap = "break-word";
            pre.innerHTML = message;
            output.appendChild(pre);
        }

        function inputEnter() {
            if (connected == false) {
                if (input.value == "") {
                    return
                }
                let enterName = document.getElementById("enter_name")
                enterName.style.display = 'none'
                let uri = wsUri + "?username=" + input.value
                openWebSocket(uri)
                connected = true
            } 
            else {
                if (input.value == "") {
                    return
                }
                doSend(input.value)
            }
            input.value = ""
        }

        window.addEventListener("load", init, false);
    </script>
</head>

<body>
    <h2>WebSocket Chat</h2>
    <div id="output"></div>
    <p id="enter_name">Please enter your name</p>
    <input id="input" onchange = "inputEnter()" type="text" name="name"/>
</body>
</html>
```

## Conclusion


https://theswiftdev.com/websockets-for-beginners-using-vapor-4-and-vanilla-javascript/