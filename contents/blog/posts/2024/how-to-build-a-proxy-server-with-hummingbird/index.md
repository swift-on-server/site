---
title: "How to Build a Proxy Server with Hummingbird"
description: "Learn how to leverage the flexibility and performance of Hummingbird to build a proxy server."
image: ./assets/cover.jpg
publication: "2024/09/30 08:00:00"
tags:
    - hummingbird
    - server
authors:
    - joannis-orlandos
---

# Building a Proxy Server with Hummingbird

[Hummingbird](https://hummingbird.codes) is a powerful and flexible system for creating various web applications. Its design enables running on a tiny memory footprint, allowing it to efficiently handle a lot of throughput.

The asynchronous and flexible nature of Hummingbird allows you to create HTTP proxies extremely easily.

### Routing Requests

To create a proxy server, you can use three ways to intercept the incoming request:

The first way is to create route on the ``Router``, for example, using a (recursive) wildcard. The route associated with these paths will receive this request. It can can then modify the target server and forward the request there.

The second solution is to create a ``RouterMiddleware`` that intercepts the request. This can be applied to a route group or globally to all requests.

Finally, you can forward every request by intercepting them all in a custom ``HTTPResponder``.

Each of these solutions will need to import the necessary modules:

```swift
import AsyncHTTPClient
import Hummingbird
import Logging
import NIOCore
import NIOPosix
import ServiceLifecycle
```

## Forwarding Requests

Each of the above solutions forwards requests the same way. The actual forwarding logic is only invoked differently for each solution.

To forward a request, you need to create a new ``HTTPClientRequest`` as defined by the ``AsyncHTTPClient`` library. Then, swap the target host (your API) with a new host. You can then use the ``HTTPClient`` to send the request and receive the response.

The HTTP Client is swappable in this function, but the rest of this tutorial will use the ``HTTPClient.shared``.

```swift
func forward(
    request: Request,
    targetHost: String,
    httpClient: HTTPClient,
    context: some RequestContext
) async throws -> Response {
    // 1.
    let query = request.uri.query.map { "?\($0)" } ?? ""
    var clientRequest = HTTPClientRequest(url: "https://\(targetHost)\(request.uri.path)\(query)")
    clientRequest.method = .init(request.method)
    clientRequest.headers = .init(request.headers)

    // 2.
    let contentLength = if let header = request.headers[.contentLength], let value = Int(header) {
        HTTPClientRequest.Body.Length.known(value)
    } else {
        HTTPClientRequest.Body.Length.unknown
    }
    clientRequest.body = .stream(
        request.body,
        length: contentLength
    )

    // 3.
    let response = try await httpClient.execute(clientRequest, timeout: .seconds(60))

    // 4.
    return Response(
        status: HTTPResponse.Status(code: Int(response.status.code), reasonPhrase: response.status.reasonPhrase),
        headers: HTTPFields(response.headers, splitCookie: false),
        body: ResponseBody(asyncSequence: response.body)
    )
}
```


As you see, there are four steps to forward a request:

1. Modify the incoming ``Request``'s URL, Method and Headers to point to the target server.
2. Provide the request's ``RequestBody`` to the ``HTTPClient`` in a streaming fashion.
3. Execute the request using ``HTTPClient``.
4. Forward the ``Response`` back to the end user.

In both step 2 and step 4, the HTTP body is passed along as a stream, or specifically an ``AsyncSequence`` of ``ByteBuffer``. This allows SwiftNIO to pass along the data efficiently, whilst applying backpressure in both directions (client and remote).

Due to the design of Hummingbird, where bodies are always streamed, this is not just an efficient solution but also the easiest to implement.

### Custom Route

The first option is to create a route on the ``Router`` that will intercept the request and forward it to the target server.

Since the code is the same as the previous example, we will only need to invoke the `forward` function from within this middleware.

```swift
let router = Router()
router.get("**") { request, context in
    try await forward(
        request: request,
        targetHost: "example.com",
        httpClient: .shared,
        context: context
    )
}
```

### Middleware

For the second option you need to create a new ``RouterMiddleware``. This middleware will intercept the request and forward it to the target server.

```swift
struct ProxyServerMiddleware<Context: RequestContext>: RouterMiddleware {
    var httpClient: HTTPClient = .shared
    let targetHost: String

    func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        try await forward(
            request: request,
            targetHost: targetHost,
            httpClient: httpClient,
            context: context
        )
    }
}
```

Then, once the middleware is set up, you can ``Router.add(middleware:)`` to the router.

```swift
let router = Router()
router.add(middleware: ProxyServerMiddleware(targetHost: "example.com"))
```

### Custom Responder

The final option will implement an ``HTTPResponder``.

```swift
struct ProxyServerResponder<Context: RequestContext>: HTTPResponder {
    let targetHost: String

    func respond(to request: Request, context: Context) async throws -> Response {
        try await forward(
            request: request,
            targetHost: targetHost,
            httpClient: .shared,
            context: context
        )
    }
}
```

Then, you can set up the responder in the ``Application``.

```swift
let app = Application(
    responder: ProxyServerResponder<BasicRequestContext>(targetHost: "example.com")
)
```

## Conclusion

Hummingbird's powerful design makes it easy to stream data in- and out of your applications. This makes it a great choice for creating a proxy server. Each of the three solutions presented in this tutorial can be used to create a proxy server with Hummingbird. Choose the one that best fits your needs and enjoy the power of Hummingbird.
