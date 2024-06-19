# What's new in Hummingbird 2?

Hummingbird is a lightweight, flexible HTTP server framework written in Swift. The work on the second major version started last year and the first alpha version was tagged on the 22th of January, 2024. There are quite a lot of significant changes and under the hood improvements. It seems like the new APIs are mostly settled down at this point, so this is a great opportunity to introduce HB2. Let's dive in.

## Swift concurrency

Hummingbird 2 was built using the modern Swift concurrency APIs. Most of the NIO event loop references are replaced with async / await functions and calls. Structured concurrency is present all around the codebase and the project components, such as ``Request``, are thread safe thanks to the ``Sendable`` conformance. 

Before the async / await feature adoption, some components had a `HBAsync` prefix. Those are now removed from the v2 library. For example `HBAsyncMiddleware` is now ``MiddlewareProtocol`` or `HBAsyncResponder` is simply called ``HTTPResponder``.

It is worth to mention that HB2 is prepared for Swift 6, the project also compiles against the experimental `StrictConcurrency=complete` feature flag. 

## Swift service lifecycle v2

The [Swift service lifecycle library](https://github.com/swift-server/swift-service-lifecycle) provides a clean startup and shutdown mechanism for server applications. Hummingbird 2 uses the latest version of the library including support for graceful shutdown even for custom application services. When Hummingbird is signalled by swift-service-lifecycle to gracefully shut down, any currently running requests continue being handled. New connections and requests will not be accepted, and idle connections are shut down. Once everything's ready, Hummingbird will shut down completely.

## Hummingbird core and foundation

The [HummingbirdCore](https://github.com/hummingbird-project/hummingbird-core) repository is merged into main repository. The `HummingbirdFoundation` target was also removed and now all the Foundation extensions are part of the main Hummingbird Swift package target. This makes Hummingbird ergonomically closer to Vapor, allowing users to get started more quickly. This decision is backed by the upcoming move to the new swift-foundation library.

## Jobs framework updates

The HummingbirdJobs framework can be used to push work onto a queue, so that is  processed outside of a request. Job handlers were restructured to use ``TaskGroup`` and conform to the ``Service`` protocol from the Swift service lifecycle framework. A ``JobQueue`` can also define it's own ``JobID`` type, which helps when integrating with various database/driver implementations.

## Connection pools

The custom connection pool implementation was removed from the framework. Previously, this component offered connection pooling for PostgreSQL. Since [PostgresNIO](https://github.com/vapor/postgres-nio) has built-in support, there's no need for it anymore inside the HB framework. 

## HTTP improvements

Hummingbird 2 takes advantage of the brand new [Swift HTTP Types library](https://github.com/apple/swift-http-types). The overall support for HTTP2 and TLS is also improved a lot in the second major version.

## Router library

Hummingbird 2 features a brand new routing library, based on Swift result builders. This is a standalone project, the old route building mechanism still works, but if you prefer result builders you can try the new method by importing this lib.

Here's a little sneak-peak about the usage of the new ``RouterBuilder`` object:

@Snippet(path: "site/Snippets/hummingbird-2-routerbuilder")

There are more examples available inside the Hummingbird [RouterTests](https://github.com/hummingbird-project/hummingbird/blob/2.x.x/Tests/HummingbirdRouterTests/RouterTests.swift) file. If you are curious about the new route builder tool, that's a good place to get started, since there are no official docs just yet.

## Generic request context

The biggest change to the framework is definitely the introduction of the generic request context. Hummingbird 2.0 separates contextual objects from the `Request` type and users can define custom properties as custom `RequestContext` protocol implementations. 

The request context is associated with the reworked ``Router``, which a generic class, featuring a _Context_ type. The `BasicRequestContext` type is the default _Context_ implementation for the _Router_. The request decoder and encoder defaults to a JSON-based solution when using the base context. You can provide a custom decoder through a custom router context.

Let me show you how this new contextual router system works in practice.

## HB2 example project

This article contains a sample project, which you can download from the following [link](https://github.com/swift-on-server/whats-new-in-hummingbird-2-sample).

You can integrate Hummingbird 2 by adding it as a dependency to your project, using Swift Package Manager.

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "whats-new-in-hummingbird-2-sample",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0-beta.8"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                // .product(name: "HummingbirdRouter", package: "hummingbird"),
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "HummingbirdXCT", package: "hummingbird"),
            ]
        ),
    ]
)
```

Here's how to build a custom decoder to handle different media types on your backend server:

@Snippet(path: "site/Snippets/hummingbird-2", slice: "requestDecoder")

1. Define the custom decoder by implementing the ``RequestDecoder`` protocol.
2. Make sure that the incoming request has a `Content-Type` HTTP header field.
3. Construct a valid ``MediaType`` object from the header field.
4. Setup a custom decoder based on the media type.
5. Return the decoded object using the decoder, with the request and the context.

To use the custom decoder, let's define a custom request context. A request context is a container for the Hummingbird framework to store information needed by the framework. The following snippet demonstrates how to build one using the _RequestContext_ protocol:

@Snippet(path: "site/Snippets/hummingbird-2", slice: "requestContext")

1. Define a custom `MyRequestContext` protocol using the _RequestContext_ protocol.
2. Implement the `MyRequestContext` protocol using a `MyBaseRequestContext` struct.
3. Implement custom properties, configure them using the init method, if needed.
4. Return the custom `MyRequestDecoder` as a default request decoder implementation.

The [HummingbirdAuth](https://github.com/hummingbird-project/hummingbird-auth) library also defines a custom context (``AuthRequestContext``) in a similar way to store user auth information.

It is possible to compose multiple protocols such as _AuthRequestContext_ by conforming to all of them. This makes it easy to integrate the context with various libraries. This also allows libraries to provide middleware that accept a custom context as input, or that modify a custom context, to enrich requests. For example, enriching a request by adding the authenticated user.

Create the application instance using the `buildApplication` function.

@Snippet(path: "site/Snippets/hummingbird-2", slice: "buildApp")

1. Setup the router using the `MyBaseRequestContext` type as a custom context.
2. Add middlewares to the router, HB2 has middlewares on the router instead of the app
3. Setup a basic health route on the router, simply return with a HTTP status code
4. Add routes using the custom controller to the `api` route group
5. Build the _Application_ instance using the router and the configuration

Inside the main entrypoint you can start the server by calling the ``Application.runService()`` method:

@Snippet(path: "site/Snippets/hummingbird-2", slice: "run")

The route handlers in the `MyController` struct can access of the custom context type.

@Snippet(path: "site/Snippets/hummingbird-2", slice: "controller")

1. Register route handlers using the router group
2. Hummingbird is thread-safe, so every route handler should be marked  with `@Sendable` to propagate these thread-safety checks. 
3. It is possible to access both the request and the context in each route handler. 

As you can see there are quite a lot of changes in the latest version of the Hummingbird framework. The final release date is still unknown, but it is expected to happen within a few months, after the alpha & beta period ends. 

If have questions about Hummingbird, feel free to join the following [Discord server](https://discord.gg/fkN7FC7QJk). You can also get some inspiration from the official [Hummingbird examples](https://github.com/hummingbird-project/hummingbird-examples) repository. 

