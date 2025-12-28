---
title: "Getting Started with Hummingbird"
description: "Learn how to get started with Hummingbird 2, the modern Swift Web Framework."
image: ./assets/cover.jpg
publication: "2024/09/24 08:00:00"
featured: true
tags:
    - hummingbird
    - server
authors:
    - joannis-orlandos
---

# Getting Started with Hummingbird

[Hummingbird](https://hummingbird.codes) is a robust, feature-rich and performance-oriented web framework for Swift.

It's designed for Swift 6, making it the first web framework to do so. In this guide, you'll learn how to set up a basic Hummingbird project, run it, and create routes to handle requests.

## Setting Up

To get started with ``Hummingbird``, you'll need to set up a new project based on the [starter template](https://github.com/hummingbird-project/template). This template includes everything you need to create and deploy a basic Hummingbird app.

To create a new project based on the starter template, you can click "Use this template" on the GitHub page or clone the repository using the following command:

```sh
curl -L https://raw.githubusercontent.com/hummingbird-project/template/main/scripts/download.sh | bash -s <project-name>
```

You can also clone the template repository, and run the configure script:

```sh
git clone https://github.com/hummingbird-project/template
cd template
./configure <path to new project>
```

You now have a new Hummingbird project set up, and are ready to start building your application.

### Running the Project

To run your Hummingbird project using Swift Package Manager (SwiftPM), navigate to the root directory of your project and run the following command:

```sh
swift run
```

This will download any dependencies and build your project, before starting the server. You can then navigate to `http://localhost:8080` in your browser to see your empty Hummingbird app in action.

When using Xcode, you can double-click on- or otherwise open the `Package.swift` file. This will open the entire folder as a project.
From here, you can build and run your project as normal.

Finally, you can use Visual Studio Code to develop and run apps as well. More on that in [Developing with Swift in Visual Studio Code](/developing-with-swift-in-visual-studio-code/)

## Project Structure

The Hummingbird project template includes only two files:

`App.swift` containing your Command Line arguments, and ``AsyncParsableCommand/run()`` function. The type is `@main` annotated, making this is the entrypoint for your app.

From here, the app calls into `buildApplication`, which is located in `Application+build.swift`.

Once the app is configured in `buildApplication`, the server is started by calling ``Application.runService(gracefulShutdownSignals:)``.

Running services starts Hummingbird and all registered dependencies (``Service``s). This kicks off ``ServiceLifecycle``, which manages your app's lifecycle. For now, services are not important to understand in detail, but you can learn about them in detail here: [Introduction to Swift Service Lifecycle](/introduction-to-swift-service-lifecycle/)

### Configuring the App

The `buildApplication` function is where you configure your Hummingbird ``Application``. This is where you register your routes, middleware, and services.

In essence, an Application just needs an ``HTTPResponder``. This type receives incoming ``Request``s from Hummingbird, and responds with a ``Response``.

You can create your own ``HTTPResponder`` by conforming to that protocol. Most commonly, you'll be using one of the router types. The default router type is simply called ``Router``.

## Routers, Routing and Routes

Routers are objects that take incoming requests route them to the appropriate handler. Handlers are simply functions that take a ``Request`` and return a ``Response``. They're the core of your backend logic.

Each of these route handlers is registered to a ``RouterPath``. When an incoming request is received, the ``Request/uri`` and ``Request/method`` are matched against the registered paths. If a match is found, the handler is called with that request.

There are two default routers in Hummingbird. The basic ``Router`` uses a Trie to organise routes. There's also a separate ``HummingbirdRouter`` module can be opted-into, which contains a result-builder style router called ``RouterBuilder``.

Both are roughly equivalent in performance. While the RouterBuilder is faster in small apps, the regular (trie-based) Router scales much better to bigger apps.

You can read up on the result builder routers [here](https://docs.hummingbird.codes/2.0/documentation/hummingbirdrouter).

### Context

Before adding routes, a Router is created:

```swift
typealias AppRequestContext = BasicRequestContext
let router = Router(context: AppRequestContext.self)
```

Notice that a "context" is provided here. An instance of this context is created for each request that passes through your Hummingbird server. The default one is ``BasicRequestContext``, but you can customise this to your needs. A context must be a concrete type, and can conform to many protocols. Through this system, you can integrate with various different libraries that need to inject or read properties.

### Adding a Route

In the template, the first route has already been created. This is a `GET /health` route, as indicated in the function signature:

```swift
router.get("/health") { _, _ -> HTTPResponse.Status in
    return .ok
}
```

This route is a simple health check that returns a 200 OK status code. You can test this route by navigating to `http://localhost:8080/health` in your browser. Although it returns a status code, the body is empty, meaning you'll see an empty page.

A route handler has two input parameters: a ``Request`` first, and the Context second. Since the AppRequestContext is set to ``BasicRequestContext``, you'll find that type in here.

Let's add a new GET route at the `/` path. This means that visiting your server at `http://localhost:8080` you'll see the response.

```swift
router.get("/") { _, _ -> String in
    return "My app works!"
}
```

Rebuild and re-run your app, using Xcode, `swift run` or your other preferred method. Note that we've changed the return type to ``String`` to return a body.

You can return any type that conforms to ``ResponseGenerator``. A full list of these types can be found [here](https://swiftinit.org/ptcl/hummingbird/hummingbird/responsegenerator).

Now, when you navigate to `http://localhost:8080`, you'll see the message "My app works!".

## Responses

While returning these simple types is a nice way to get started, you'll quickly find that you need to return more complex responses. Hummingbird embraces Codable for this, although any other system can be used as well.

Create a type that conforms to ``ResponseCodable``, and return that from your route handler. This type will be encoded to the response body.

```swift
struct MyResponse: ResponseCodable {
    let message: String
}

router.get("/message") { _, _ -> MyResponse in
    return MyResponse(message: "Hello, world!")
}
```

This route will return a JSON response with the message "Hello, world!" encoded within!

From here, just run the app!

```swift
let app = Application(router: router)
try await app.runService()
```

## Conclusion

In this guide, you've learned how to set up a new Hummingbird project, run it, and create routes to handle requests. You also learned how to return simple and complex responses. With this foundation, you're ready to start building your own Hummingbird applications! For more advanced topics, check out the [Hummingbird documentation](https://docs.hummingbird.codes) and our other tutorials! Happy coding!
