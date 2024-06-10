# WebSocket tutorial using Swift and Hummingbird

In this article, you will learn about WebSockets and how to use them with the Hummingbird framework in a straightforward, easy-to-follow manner. The first part will give a clear understanding of what the WebSocket protocol is. After that, a hands-on example will be created using the Hummingbird WebSocket library, showing how to use this technology effectively.

## What is a WebSocket?

WebSocket is a communication protocol that enables two-way, real-time interaction between an HTTP client and server. It is designed to work over a single, long-lived connection, which significantly reduces overhead compared to traditional HTTP request-response cycles. This protocol uses HTTP 1 to establish the connection, and then upgrades it to the WebSocket protocol, allowing both the client and server to send and receive messages asynchronously.

WebSockets are particularly useful for applications that require low latency and high-frequency updates, such as online gaming, chat applications, and live data feeds. The protocol supports full-duplex communication, meaning data can be sent and received simultaneously. This efficient data transfer method helps in creating more interactive applications, providing a smoother user experience.

## WebSockets vs long polling vs HTTP streaming, and server-sent events

Similar to WebSockets, there are other methods of achieving real-time capabilities. Techniques like HTTP polling, HTTP streaming, Comet, and SSE (server-sent events) come to mind. Let’s explore how these methods differ.

### Long polling (HTTP polling)

Long polling (HTTP polling) was one of the first methods to address real-time data fetching. It involved the client repeatedly sending requests to the server. The server holds the request open until there’s new data or a timeout occurs. Once data is available, the server responds, and the client immediately sends a new request. However, long polling has several issues, including header overhead, latency, timeouts, and caching problems.

### HTTP streaming

HTTP streaming reduces network latency by keeping the initial request open indefinitely. Unlike long polling, the server does not close the connection after sending data; it keeps it open to send new updates whenever there is a change.

### SSE - Server-sent events

Server-sent events (SSE) allow the server to push data to the client, similar to HTTP streaming. SSE is a standardized version of HTTP streaming and includes a built-in browser API. However, SSE is not suitable for applications like chats or games that require two-way communication since it only allows a one-way data flow from the server to the client. SSE uses traditional HTTP and has limitations on the number of open connections.

## Why to use WebSockets?

Compared to WebSockets, these methods are less efficient and often seem like workarounds to make a request-reply protocol appear full-duplex. WebSockets are designed to replace existing bidirectional communication methods, as the previously mentioned methods are neither reliable nor efficient for full-duplex real-time communication. WebSockets are similar to SSE but excel in enabling messages to be sent from the client to the server. Connection restrictions are no longer an issue because data is transmitted over a single TCP socket connection.

### Security (WSS)

WebSocket (WS) uses a plain-text HTTP protocol, making it less secure and easy to intercept. WebSocket Secure (WSS), like HTTPS, encrypts data with SSL/TLS, preventing interception and increasing security. WSS protects against man-in-the-middle attacks but does not offer cross-origin or application-level security. Developers should add URL origin checks and strong authentication. 

## How to use WebSockets to build a real-time chat application?

The [Hummingbird Websocket](https://github.com/hummingbird-project/hummingbird-websocket) library is an extension for the Hummingbird web framework, designed to provide WebSocket support. This library simplifies the implementation of WebSocket connections by handling message sending and receiving, and efficiently managing multiple connections using the latest structured concurrency features like task groups and async streams.

The [Hummingbird WebSocket chat application](https://github.com/hummingbird-project/hummingbird-examples/tree/main/websocket-chat) demonstrates using web sockets for real-time communication. For an even simpler example, see the [echo server](https://github.com/hummingbird-project/hummingbird-examples/tree/main/websocket-echo). This article will explore the chat application step-by-step. Let’s begin with the directory structure.

```sh
.
├── Package.resolved
├── Package.swift
├── README.md
├── Sources
│   └── App
│       ├── App.swift
│       ├── Application+build.swift
│       └── ConnectionManager.swift
└── public
    └── chat.html
```

The `App.swift` file contains the standard entry point for a Hummingbird application. The `Application+build.swift` file includes the Hummingbird app configuration using the WebSocket connection manager. The `ConnectionManager` is responsible for managing WebSocket connections. The `public/chat.html` file contains client-side JavaScript code to demonstrate a WebSocket connection.

To add WebSocket support to a Hummingbird-based Swift package, simply include the Hummingbird Websocket library as a dependency in your `Package.swift` file..

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

The `App.swift` file is the main entry point for a Hummingbird application using the ``ArgumentParser`` library. 

```swift
import ArgumentParser
import Hummingbird

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

```

1.	The ``AppArguments`` protocol defines hostname and port properties.
2.	The `HummingbirdArguments` structure is the main entry point, using ``AsyncParsableCommand``, and sets command-line options.
3.	The run function builds the Hummingbird application and starts the server as a service.

The code inside the `Application+build.swift` file sets up a Hummingbird application configured for WebSocket communication. It defines a function buildApplication that takes command-line arguments for hostname and port, initializes a logger, and sets up routers with middlewares for logging and file handling. It creates a `ConnectionManager` for managing WebSocket connections and configures the WebSocket router to handle chat connections, upgrading the connection if a username is provided. The application is configured to use HTTP with WebSocket upgrades and includes WebSocket compression. Finally, the application is returned with the necessary services added.


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
```

1. A `Router` instance is created, and middlewares for logging requests and serving files are added to it.
2. A `ConnectionManager` instance is created with a logger for managing WebSocket connections.
3. A separate `Router` instance is created specifically for handling and logging WebSocket requests.
4. A WebSocket route is set up for the `chat` path, checking for a username query parameter for WebSocket upgrades.
5. On upgrade, the connection manager handles WebSocket users and writes the output stream to the outbound channel.
6. An `Application` instance is created with the previously configured routers for both HTTP and WebSocket requests.
7. The `ConnectionManager` is added as a service to the application before returning it.

The `ConnectionManager` struct manages WebSocket connections, allowing users to join, send messages, and leave the chat, using an `AsyncStream` for connection handling and Actor for managing outbound connections. It includes methods for adding and removing users, broadcasting messages, and gracefully handling shutdowns:


```swift
import AsyncAlgorithms
import Hummingbird
import HummingbirdWebSocket
import Logging
import NIOConcurrencyHelpers
import ServiceLifecycle

// 1.
struct ConnectionManager: Service {

    // 2.
    typealias OutputStream = AsyncChannel<WebSocketOutboundWriter.OutboundFrame>

    // 3.
    struct Connection {
        let name: String
        let inbound: WebSocketInboundStream
        let outbound: OutputStream
    }

    // 4.
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


    func run() async {.
        await withGracefulShutdownHandler {
            await withDiscardingTaskGroup { group in
                let outboundCounnections = OutboundConnections()
                // 5.
                for await connection in connectionStream {
                    group.addTask {
                        logger.info("add connection", metadata: [
                            "name": .string(connection.name)
                        ])
                        // 6.
                        await outboundCounnections.add(
                            name: connection.name,
                            outbound: connection.outbound
                        )

                        do {
                            // 7.
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
                                // 8.
                                await outboundCounnections.send(output)
                            }
                        } catch {}

                        logger.info("remove connection", metadata: [
                            "name": .string(connection.name)
                        ])
                        // 9.
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

1. The `ConnectionManager` implements the ``Service`` protocol to manage WebSocket connections and ensure graceful shutdown.
2. `OutputStream` is defined as an ``AsyncChannel`` for sending WebSocket outbound frames.
3. The `Connection` struct contains details about each WebSocket connection, including the username, inbound stream, and outbound stream.
4. The `OutboundConnections` actor manages a dictionary of outbound writers to broadcast messages to all connections.
5. The `run` function iterates through the `connectionStream` asynchronously to handle incoming connections and messages.
6. For each connection, a task is added to the group to manage the connection and broadcast the "joined" message.
7. The task listens for incoming messages, processing text messages to broadcast to all connections.
8. Each received text message is broadcast to all outbound connections by calling `send`.
9. Upon connection termination, the connection is removed, a "left" message is broadcast, and the outbound stream is finished.


The `public/chat.html` file contains all the client-side HTML and JavaScript code necessary for the WebSocket chat application. Upon loading, the page initializes the input and output elements and establishes a WebSocket connection. Users can enter their names to initiate the connection and send messages. Server messages are displayed in the output area. The application handles WebSocket events, such as opening, closing, receiving messages, and errors, updating the display as needed.

```html
<!DOCTYPE html>
<head>
    <meta charset="utf-8" />
    <title>WebSocket Chat</title>
    <script language="javascript" type="text/javascript">

        // 1.
        var wsUri = "ws://localhost:8080/chat";
        var connected = false;
        var input;
        var output;

        // 2. 
        function init() {
            input = document.getElementById("input");
            output = document.getElementById("output");
            input.value = ""
        }

        // 3.
        function openWebSocket(uri) {
            websocket = new WebSocket(uri);
            websocket.onopen = function(evt) { onOpen(evt) };
            websocket.onclose = function(evt) { onClose(evt) };
            websocket.onmessage = function(evt) { onMessage(evt) };
            websocket.onerror = function(evt) { onError(evt) };
        }

        function onOpen(evt) {
          
        }

        // 4.
        function onClose(evt) {
            writeToScreen("DISCONNECTED");
            connected = false
            let enterName = document.getElementById("enter_name")
            enterName.style.display = 'block'
        }

        // 5.
        function onMessage(evt) {
            writeToScreen('<span style="color: blue;">' + evt.data + '</span>');
        }

        // 6.
        function onError(evt) {
            writeToScreen('<span style="color: red;">ERROR:</span> ' + evt);
        }

        // 7.
        function doSend(message) {
            websocket.send(message);
        }

        // 8.
        function writeToScreen(message) {
            var pre = document.createElement("p");
            pre.style.wordWrap = "break-word";
            pre.innerHTML = message;
            output.appendChild(pre);
        }

        // 9.
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

        // 10.
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

1. The `wsUri` variable is set to the WebSocket server URL, and initial states for connection status, input, and output are declared.
2. The `init` function initializes the input and output elements and resets the input value.
3. The `openWebSocket` function establishes a WebSocket connection and sets up event handlers for open, close, message, and error events.
4. The `onClose` function handles the WebSocket closing event by displaying a disconnected message and showing the name input field again.
5. The `onMessage` function handles incoming WebSocket messages by displaying them in the output area with blue text.
6. The `onError` function handles WebSocket errors by displaying an error message in red.
7. The `doSend` function sends a message through the WebSocket connection.
8. The `writeToScreen` function creates a new paragraph element to display messages in the output area.
9. The `inputEnter` function manages user input, either connecting to the WebSocket server with the entered username or sending messages if already connected.
10. The `window.addEventListener` function sets up the `init` function to run when the page loads.

Make sure the [custom working directory](https://theswiftdev.com/custom-working-directory-in-xcode/) is set to the root folder before starting the app.

Run the app and navigate to `http://localhost:8080/chat.html` in a web browser, enter a name, and start chatting. Open another browser window to create a second connection and chat between the two pages. The app includes a simple connection manager for handling WebSocket connections. 

## Conclusion

This article demonstrated how to use WebSockets with the Hummingbird framework to build a real-time chat application in Swift. For a similar guide on the Vapor web framework, check out [this article](https://theswiftdev.com/websockets-for-beginners-using-vapor-4-and-vanilla-javascript/). Hummingbird 2 leverages modern Swift concurrency features for handling WebSocket connections, offering a significant advantage over other frameworks. For more information on Swift concurrency, feel free to explore our additional articles about [structured concurrency](https://swiftonserver.com/getting-started-with-structured-concurrency-in-swift/).

