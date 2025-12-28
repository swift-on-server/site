---
title: "Using Hummingbird's Request Contexts"
description: "Learn about request contexts in Hummingbird and how to use them."
image: ./assets/cover.jpg
publication: "2024/10/1 08:00:00"
tags:
    - hummingbird
    - server
authors:
    - joannis-orlandos
---

# Using Hummingbird's Request Context

[Hummingbird](https://hummingbird.codes) introduces a new feature that is essential in how it integrates with other libraries: the ``RequestContext``.

This article explains what they're used for, and how they can help you build statically checked and performant applications.

## The Core

This protocol is implemented by metadata containers. Alongside each ``Request``, Hummingbird creates one instance of this Context. This context functions as a metadata container, and stores properties alongside the request.

The ``RequestContext`` protocol has one main requirement: It needs store a ``CoreRequestContextStorage``.

The CoreRequestContextStorage is a container that the framework uses to store properties _it needs_. While the amount of properties are limited right now, this allows the framework to add more features in the future without breaking your code.

In addition, a context can specify a ``RequestDecoder`` and ``ResponseEncoder``. These types can read the headers and body of a request, and encode a response body, respectively. This is usually backed by a codable implementation such as ``JSONEncoder``. Since Swift bundles a JSON implementation through Foundation, this is the default.

While the en- and decoder usually focus on one content type such as JSON, it's also possible for a context to support multiple content types.

Finally, a request specifies ``RequestContext/maxUploadSize [requirement]``, which has a sensible default value. This specifies the maximum amount of data that Hummingbird may send to a ``RequestDecoder`` before rejecting the request.

## Custom Contexts

Hummingbird provides a very simple context called ``BasicRequestContext``, which is used by default. It's a good starting point for applications, but most applications need custom contexts.

To create a custom context, create a struct that conforms to the ``RequestContext`` protocol. This struct stores any properties related to the request.

```swift
struct CustomContext: RequestContext {
    var coreContext: CoreRequestContextStorage
    var token: String?

    init(source: ApplicationRequestContextSource) {
        self.coreContext = .init(source: source)
    }
}
```

The context is not to be used for dependency injection, such as a database connection. If a property is shared between requests, inject that type in the controller instead. <!-- TODO: Tutorial -->

From here, instantiate a ``Router`` instance using the new context as a basis.

```swift
let router = Router(context: CustomContext.self)
```

### Authentication

When working with Hummingbird, contexts are a very essential part of any application. It's the glue between the framework, other libraries and routes.

So far you've seen the context be used to relay information on a request level between the framework, middlewares and routes. However, some libraries need to know more contextual information. For example, a JWT library can provide knowledge on the user that is making the request.

To do this, you can extend your context with a new property that stores the user information. This can be a simple struct that stores the user's ID, or a more complex type that stores the user's permissions.

### Middleware

<!-- TODO: Middleware tutorial -->

Middleware are powerful tools that allow intercepting requests and responses, and modify them as needed. This is a great place to add authentication, logging, or other cross-cutting concerns.

In Hummingbird, the middleware system is also designed with contexts in mind. When a request is received, the context is created and along between middleware. The middleware can then modify the context as needed.

First, create a middleware type that conforms to the ``RouterMiddleware`` protocol. Then, modify the properties in the context from the ``MiddlewareProtocol/handle(_:context:next:)`` method.

While middleware can specify a `typealias` to constrain to a specific context, it's also possible make a middleware generic.

```swift
struct SimpleAuthMiddleware: RouterMiddleware {
    typealias Context = CustomContext

    func handle(
        _ input: Request, 
        context: Context, 
        next: (Request, Context) async throws -> Output
    ) async throws -> Response {
        var context = context
        guard
            let token = input.headers[.authorization]
        else {
            throw HTTPError(.unauthorized)
        }

        // Note: This is still not secure.
        // Token verification is missing from this example
        context.token = token

        // Pass along the chain to the next handler 
        //      (middleware or route handler)
        return try await next(input, context)
    }

```

### Context Protocols

In the example above, the middleware specifies the type of Context it needs. However, using the power of Swift's generics, it's possible to make a middleware that works with different custom ``RequestContext``s.

First, specify a protocol that the context must conform to. This protocol can be as simple as a marker protocol, or it can specify properties that the middleware needs.

```swift
protocol AuthContext: RequestContext {
    var token: String? { get set }
}
```

Then, remove the `typealias` and replace it with a generic parameter. This parameter is constrained to the new protocol.

```swift
struct AuthMiddleware<Context: AuthContext>: RouterMiddleware {

    func handle(
        _ input: Request, 
        context: Context, 
        next: (Request, Context) async throws -> Output
    ) async throws -> Response {
        var context = context
        guard
            let token = input.headers[.authorization]
        else {
            throw HTTPError(.unauthorized)
        }

        // Note: This is still not secure.
        // Token verification is missing from this example
        context.token = token

        // Pass along the chain to the next handler 
        //      (middleware or route handler)
        return try await next(input, context)
    }
}
```

That's all you need to do! Now, the middleware can be used with any context that conforms to the protocol.

## Conclusion

Many of Hummingbird's features are built around the ``RequestContext``. It's a powerful tool that allows you to build statically checked and performant applications. By using the context, you can integrate with other libraries, add authentication, and more.

For more information, check out the [Hummingbird documentation](https://docs.hummingbird.codes) and our other tutorials! Happy coding!
