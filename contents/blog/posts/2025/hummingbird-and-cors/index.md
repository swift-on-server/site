---
title: "Hummingbird and CORS"
description: "Learn how to use Hummingbird and CORS in Swift"
image: ./assets/cover.jpg
publication: "2025/01/20 9:00:00"
tags:
    - hummingbird
    - server
authors:
    - joannis-orlandos
---

# Hummingbird and CORS

If you've stumbled upon this tutorial, you've likely seen a browser error that looks something like this:

```
Access to fetch at 'http://localhost:8080/api' from origin 'http://localhost:3000' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource. If an opaque response serves your needs, set the request's mode to 'no-cors' to fetch the resource with CORS disabled.
```

CORS (Cross-Origin Resource Sharing) is a security feature that's implemented by web browsers. It prevents malicious websites from making requests to other websites.

### How does CORS work?

Before a browser makes the request to a server, it sends a preflight (OPTIONS) request to the server to ask for permission to make the request. The server then responds with a list of allowed origins, methods, and headers. If the browser's request matches the server's response, the browser will make the request.

While this is a great security feature, it's often confusing the first time it blocks requests.

## How to handle CORS in Hummingbird

Hummingbird has built-in support for CORS through ``CORSMiddleware``. <!-- TODO: Middleware tutorial -->
Because CORSMiddleware is a ``RouterMiddleware``, it can be applies to all - or just a subset of routes.

```swift
router.add(middleware: CORSMiddleware())
```

In the above example, the middleware is configured in its default configuration. This setup will allow all origins to make requests using a set of standard HTTP headers and methods.

This is a great starting point, and allows you to make most API requests. However, you may want to configure the middleware to be more restrictive or permissive.

### Configuring the CORSMiddleware

The ``CORSMiddleware`` initializer has a few parameters that you can use to configure it. The first one is the ``CORSMiddleware/AllowOrigin`` parameter.

There are three standard cases:

- ``CORSMiddleware/AllowOrigin.all``: Allows all origins to make requests.
- ``CORSMiddleware/AllowOrigin.custom(_:)``: Allows requests from a specific origin.
- ``CORSMiddleware/AllowOrigin.none``: Allows no origins to make requests.

This ``CORSMiddleware/AllowOrigin`` parameter is used to specify which origins are allowed to make requests.

The other variables are:
- `allowHeaders`, which specifies what headers are allowed to be sent with the request. This is an array of ``HTTPField.Name`` values.
- `allowMethods`, specifying what HTTP methods are allowed to be used when making requests. This is an array of ``HTTPRequest.Method`` values.
- `allowCredentials`, which specifies if users credentials (cookies, TLS client certificates, authorization headers, etc.) are allowed to be sent with the request. This is a boolean value.
- `maxAge`, which specifies the maximum amount of time (in seconds) that the browser can cache the preflight response. This is a ``TimeAmount`` value.

### Example

Let's look at an example of how to configure the middleware.

```swift
router.add(middleware: CORSMiddleware(
    allowOrigin: .custom("http://example.com"),
    allowHeaders: [.accept, .contentType],
    allowMethods: [.get, .post],
    allowCredentials: true,
    maxAge: .seconds(3600))
)
```

In the above example, the middleware is configured to allow requests from `http://example.com` using the `GET` and `POST` methods. It allows the `Accept` and `Content-Type` headers and sets the maximum age of the preflight response to 1 hour.

## Summary

CORS is a security feature that's implemented by web browsers. It prevents malicious websites from making requests to other websites. Hummingbird has built-in support for CORS through ``CORSMiddleware``.

When you inevitably run into CORS errors, you now know how to configure ``CORSMiddleware`` to allow requests from your frontends.
