# WebSocket tutorial using Swift and Hummingbird

In this article, you will learn about WebSockets and how to use them with the Hummingbird framework in a straightforward, easy-to-follow manner. The first part will give a clear understanding of what the WebSocket protocol is. After that, a hands-on example will be created using the Hummingbird WebSocket library, showing how to use this technology effectively.

## What is a WebSocket?

WebSocket is a communication protocol that enables two-way, real-time interaction between an HTTP client and server. It is designed to work over a single, long-lived connection, which significantly reduces overhead compared to traditional HTTP request-response cycles. This protocol uses HTTP 1 to establish the connection, and then upgrades it to the WebSocket protocol, allowing both the client and server to send and receive messages asynchronously.

WebSockets are particularly useful for applications that require low latency and high-frequency updates, such as online gaming, chat applications, and live data feeds. The protocol supports full-duplex communication, meaning data can be sent and received simultaneously. This efficient data transfer method helps in creating more interactive applications, providing a smoother user experience.

## WebSockets vs Alternatives

Similar to WebSockets, there are other methods of achieving real-time capabilities. Techniques like HTTP polling, HTTP streaming, Comet, and SSE (server-sent events) come to mind. Let’s explore how these methods differ.

### Long polling (HTTP polling)

Long polling (HTTP polling) was one of the first methods to address real-time data fetching. It involved the client repeatedly sending requests to the server. The server holds the request open until there’s new data or a timeout occurs. Once data is available, the server responds, and the client immediately sends a new request. However, long polling has several issues, including header overhead, latency, timeouts, and caching problems.

### HTTP streaming

HTTP streaming reduces network latency by keeping the initial request open indefinitely. Unlike long polling, the server does not close the connection after sending data; it keeps it open to send new updates whenever there is a change.

### SSE - Server-sent events

Server-sent events (SSE) allow the server to push data to the client, similar to HTTP streaming. SSE is a standardized version of HTTP streaming and includes a built-in browser API. However, SSE is not suitable for applications like chats or games that require two-way communication since it only allows a one-way data flow from the server to the client. SSE uses traditional HTTP and has limitations on the number of open connections.

## Why to use WebSockets?

The above methods are less efficient on a protocol level and often seem like workarounds to make a request-reply protocol appear full-duplex. WebSockets are designed for full-duplex communication, and are more lightweight than its alternatives.

### Security (WSS)

WebSocket (WS) uses a plain-text TCP connection. A WebSocket connection is created by upgrading an HTTP/1 connection. WebSocket Secure (WSS), which is upgraded from HTTPS, uses TLS to protect the TCP connection. WSS protects against man-in-the-middle attacks but does not offer cross-origin or application-level security. Developers should add URL origin checks and strong authentication. 

## Building a real-time WebSocket chat

<!-- TODO: link AsyncSequences article when it's ready -->

The [Hummingbird Websocket](https://github.com/hummingbird-project/hummingbird-websocket) library is an extension for the Hummingbird web framework. This library provides WebSocket Client- and Serve support using the latest structured concurrency features like ``TaskGroup`` and ``AsyncSequence``s.

The [Hummingbird WebSocket chat application](https://github.com/hummingbird-project/hummingbird-examples/tree/main/websocket-chat) example demonstrates using web sockets for real-time communication. For an even simpler example, see the [echo server](https://github.com/hummingbird-project/hummingbird-examples/tree/main/websocket-echo) example. This article will explore the chat application step-by-step. Let’s begin with the directory structure.

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

The `App.swift` file contains the standard entry point for a Hummingbird application. The `Application+build.swift` file includes the Hummingbird app configuration using the WebSocket connection manager. The ``ConnectionManager`` is responsible for managing WebSocket connections. The `public/chat.html` file contains client-side JavaScript code to demonstrate a WebSocket connection.

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
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0-rc.1"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.0.0-beta.5"),
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

@Snippet(path: "site/Snippets/websockets", slice: "entrypoint")

1.	The ``AppArguments`` protocol defines hostname and port properties.
2.	The `HummingbirdArguments` structure is the main entry point, using ``AsyncParsableCommand``, and sets command-line options.
3.	The run function builds the Hummingbird application and starts the server as a service.

The code inside the `Application+build.swift` file sets up a Hummingbird application configured for WebSocket communication. It defines a function buildApplication that takes command-line arguments for hostname and port, initializes a logger, and sets up routers with middlewares for logging and file handling. It creates a ``ConnectionManager`` for managing WebSocket connections and configures the WebSocket router to handle chat connections, upgrading the connection if a username is provided:

@Snippet(path: "site/Snippets/websockets", slice: "buildApplication")

1. A ``Router`` instance is created, and middlewares for logging requests and serving files are added to it.
2. A ``ConnectionManager`` instance is created with a logger for managing WebSocket connections.
3. A separate ``Router`` instance is created specifically for handling and logging WebSocket requests.
4. A WebSocket route is set up for the `/chat` path, checking for a username query parameter for WebSocket upgrades.
5. On upgrade, the connection manager handles WebSocket users and writes the output stream to the outbound channel.

The application is configured to use HTTP with WebSocket upgrades and includes WebSocket compression. Finally, the application is returned with the necessary services added:

@Snippet(path: "site/Snippets/websockets-app")

1. An `Application` instance is created with the previously configured routers for both HTTP and WebSocket requests.
2. The `ConnectionManager` is added as a service to the application before returning it.

The ``ConnectionManager`` struct manages WebSocket connections, allowing users to join, send messages, and leave the chat, using an `AsyncStream` for connection handling and Actor for managing outbound connections:

@Snippet(path: "site/Snippets/websockets-connection-manager-types")

1. The ``ConnectionManager`` implements the ``Service`` protocol to manage WebSocket connections and ensure graceful shutdown.
2. ``OutputStream`` is defined as an ``AsyncChannel`` for sending WebSocket outbound frames.
3. The ``Connection`` struct contains details about each WebSocket connection, including the username, inbound stream, and outbound stream.
4. The ``OutboundConnections`` actor manages a dictionary of outbound writers to broadcast messages to all connections.

The ``addUser`` function creates a ``Connection`` object with a given name and WebSocket streams, yields this connection, and returns a new ``OutputStream``:

@Snippet(path: "site/Snippets/websockets-connection-manager-add-user")

The ``init(logger:)`` method creates an asynchronous stream for ``Connection`` objects along with a logger, and the ``run`` function asynchronously handles connections by logging their addition, processing inbound messages, sending outbound messages, and logging their removal, with graceful shutdown support:

@Snippet(path: "site/Snippets/websockets", slice: "ConnectionManager")

1. The ``run`` function iterates through the `connectionStream` asynchronously to handle incoming connections and messages.
2. For each connection, a task is added to the group to manage the connection and broadcast the "joined" message.
3. The task listens for incoming messages, processing text messages to broadcast to all connections.
4. Each received text message is broadcast to all outbound connections by calling `send`.
5. Upon connection termination, the connection is removed, a "left" message is broadcast, and the outbound stream is finished.

Make sure the [custom working directory](https://theswiftdev.com/custom-working-directory-in-xcode/) is set to the root folder before starting the app. Client communication with the WebSocket server can be established using the `ws://localhost:8080/chat` endpoint.

Execute the app and open a web browser to navigate to the [WebSocket Tester Tool](https://websocketman.com/) website. To initiate a chat connection, input the following URL into the designated field:

```
ws://localhost:8080/chat?username=Tib
```

The `username` parameter can be modified as needed. Press the _Connect_ button to add a new user to the chat room. Upon connection, messages can be sent as the user by entering a custom message and clicking the _Send Message_ button. Multiple windows of the WebSocket Tester Tool can be opened to add additional users. 

## Conclusion

This article demonstrated how to use WebSockets with the Hummingbird framework to build a real-time chat application in Swift. For a similar guide on the Vapor web framework, check out [this article](https://theswiftdev.com/websockets-for-beginners-using-vapor-4-and-vanilla-javascript/). Hummingbird 2 leverages modern Swift concurrency features for handling WebSocket connections, offering a significant advantage over other frameworks. For more information on Swift concurrency, dive into our additional articles about [structured concurrency](https://swiftonserver.com/getting-started-with-structured-concurrency-in-swift/).

