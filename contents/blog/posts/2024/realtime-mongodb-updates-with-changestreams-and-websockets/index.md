---
title: "Realtime MongoDB Updates with ChangeStreams and WebSockets"
description: "Learn how to implement real-time updates over WebSockets using ChangeStreams and MongoKitten"
image: ./assets/cover.jpg
publication: "2024/12/28 9:00:00"
tags:
  - databases
  - hummingbird
authors:
  - joannis-orlandos
---

# Real-time MongoDB Updates over WebSockets

Learn how to create a real-time feed of MongoDB changes using ChangeStreams and WebSockets. This tutorial demonstrates how to stream database changes to connected clients using MongoKitten and Hummingbird.

## Overview

In this tutorial, you'll learn how to:
- Create a real-time post feed using MongoDB ChangeStreams
- Set up a WebSocket server with Hummingbird
- Implement a REST endpoint for creating posts
- Broadcast changes to WebSocket clients
- Handle WebSocket connections safely using Swift concurrency

### Prerequisites

This tutorial builds upon concepts from:
- [Getting Started with MongoDB in Swift using MongoKitten](/getting-started-with-mongokitten/)
- [WebSocket tutorial using Swift and Hummingbird](/websockets-tutorial-using-swift-and-hummingbird/)


Make sure you have MongoDB running locally before starting.

## The Connection Manager

The `ConnectionManager` handles WebSocket connections and MongoDB change notifications:

```swift
actor ConnectionManager {
    private let database: MongoDatabase
    private var outboundConnections: [UUID: WebSocketOutboundWriter] = [:]
    
    init(database: MongoDatabase) {
        self.database = database
    }
    
    func broadcast(_ data: Data) async {
        guard let text = String(data: data, encoding: .utf8) else {
            return
        }
        
        for connection in outboundConnections.values {
            try? await connection.write(.text(text))
        }
    }

    func withRegisteredClient<T: Sendable>(
        _ client: WebSocketOutboundWriter,
        perform: () async throws -> T
    ) async throws -> T {
        let id = UUID()
        outboundConnections[id] = client
        defer { outboundConnections[id] = nil }
        return try await perform()
    }
}
```

1. The manager is an actor to ensure thread-safe access to connections
2. It maintains a dictionary of active WebSocket connections
3. The `broadcast` method sends updates to all connected clients
4. `withRegisteredClient` safely manages client lifecycle using structured concurrency

The use of `withRegisteredClient` ensures that the WebSocket connection is properly cleaned up when the connection is closed. This pattern is very scalable.

> Tip: Watch [Franz' Busch talk](https://www.youtube.com/watch?v=JmrnE7HUaDE) on this topic for a deeper dive into this pattern.

### Watching for Changes

Now that the `ConnectionManager` is implemented, we can watch for changes in the MongoDB database. For this, we'll tie the `ConnectionManager` to the application lifecycle using the ``Service`` protocol.

```swift
extension ConnectionManager: Service {
    func run() async throws {
        // 1.
        let posts = database["posts"]
        
        // 2.
        let changes = try await posts.watch(type: Post.self)
        
        // 3.
        for try await change in changes {
            // 4.
            if change.operationType == .insert, let post = change.fullDocument {
                // 5.
                let jsonData = try JSONEncoder().encode(post)
                // 6.
                await broadcast(jsonData)
            }
        }
    }
}
```

1. Get a reference to the posts collection
2. Create a change stream watching for post changes
3. Loop over each change
4. If the change is an insert, take the decoded post
5. Encode the post as JSON
6. Broadcast the post to all connected clients

This flow is very scalable, as only one ChangeStream is created and maintained per Hummingbird instance. At the same time, the use of structured concurrency ensures that the ChangeStream is properly cleaned up when the application shuts down.

## Setting Up the Application

Let's create the main application entry point:

```swift
@main
struct RealtimeMongoApp {
    static func main() async throws {
        // 1.
        let db = try await MongoDatabase.connect(to: "mongodb://localhost/social_network")
        
        // 2.
        let connectionManager = ConnectionManager(database: db)


        let router = Router(context: BasicRequestContext.self)
        setupRoutes(router: router, db: db)
        
        // 4.
        var app = Application(
            router: router,
            server: .http1WebSocketUpgrade { request, channel, logger in
                return .upgrade([:]) { inbound, outbound, context in
                    try await connectionManager.withRegisteredClient(outbound) {
                        for try await _ in inbound {
                            // Drop any incoming data, we don't need it
                            // But keep the connection open
                        }
                    }
                }
            }
        )

        // 5.
        app.addServices(connectionManager)
        
        // 6.
        try await app.runService()
    }
}
```

1. Connect to MongoDB
2. Create the connection manager
3. Setup the HTTP router with a POST endpoint for creating posts
4. Configure WebSocket support using HTTP/1.1 upgrade
5. Add the connection manager as a service
6. Run the application

### Adding Routes

```swift
func setupRoutes(router: Router<BasicRequestContext>, db: MongoDatabase) {
    router.post("/posts") { request, context -> Response in
        struct CreatePostRequest: Codable {
            let author: String
            let content: String
        }
        let post = try await request.decode(as: CreatePostRequest.self, context: context)
        try await createPost(author: post.author, content: post.content, in: db)
        return Response(status: .created)
    }
}
```

This snippet adds a POST route to the application that creates a new post in the database. That process then triggers the change streams, which broadcast to all connected clients.

## Testing the Setup

1. Start the server:

```sh
swift run
```

You can also copy the code from this tutorial's snippet into your project and run it.

2. Connect to the WebSocket endpoint:

```
ws://localhost:8080
```

3. Create a new post using curl:

```sh
curl -X POST http://localhost:8080/posts \
  -H "Content-Type: application/json" \
  -d '{"author":"Joannis Orlandos","content":"Hello, real-time world!"}'
```

You should see the new post appear immediately in your WebSocket client!

## Next Steps

You've learned how to create a real-time feed of MongoDB changes using ChangeStreams and WebSockets! Here's what you can explore next:

- Add authentication for both HTTP and WebSocket endpoints
- Implement filters for specific types of changes
- Add support for updates and deletions
- Implement message acknowledgment
- Add retry mechanisms for failed broadcasts

### Resources

- [MongoDB ChangeStreams Documentation](https://www.mongodb.com/docs/manual/changeStreams/)
- [Hummingbird WebSocket Documentation](https://github.com/hummingbird-project/hummingbird-websocket)
- [MongoKitten Documentation](https://github.com/orlandos-nl/MongoKitten)
