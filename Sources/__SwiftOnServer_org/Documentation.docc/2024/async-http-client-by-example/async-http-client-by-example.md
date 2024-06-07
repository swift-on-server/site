# AsyncHTTPClient by example

Swift ``/AsyncHTTPClient`` is an HTTP client library built on top of SwiftNIO. It provides a solid solution for efficiently managing HTTP requests by leveraging the Swift Concurrency model, thus simplifying networking tasks for developers.

The library's asynchronous and non-blocking request methods ensure that network operations do not hinder the responsiveness of the application. Additionally, the library offers TLS support, automatic HTTP/2 over HTTPS and several other convenient features.
 
The AsyncHTTPClient library is a comprehensive tool for seamless HTTP communication for server-side Swift applications. Throughout this article, we'll delve into practical [examples](https://github.com/swift-on-server/async-http-client-by-example-sample) to showcase the capabilities of this library.


## Setting up & configuring AsyncHTTPClient

Starting with this article, you can utilize a foundational code example as a starting point for integrating the Swift AsyncHTTPClient library into your Swift projects.

Now, open the `Package.swift` file in your project directory and add AsyncHTTPClient as a dependency:

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "async-http-client-by-example-sample",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0")
    ],
    targets: [
        .executableTarget(
            name: "async-http-client-by-example-sample",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
            ]
        ),
    ]
)
```

In the `main.swift` file, import the AsyncHTTPClient library and initialize an HTTPClient instance for future use:

@Snippet(id: async-http-client-01)

1. Specify the event loop group provider as ``HTTPClient/EventLoopGroupProvider.singleton``, which manages the underlying ``EventLoopGroup`` for asynchronous operations.
2. The ``HTTPClient/Configuration`` parameter is set, defining various aspects of the ``HTTPClient``'s behavior.
3. ``HTTPClient/Configuration/RedirectConfiguration`` is specified to follow redirects up to a maximum of 3 times and disallow redirect cycles.
4. Set ``HTTPClient/Configuration/Timeout``s for different phases of the HTTP request process, such as connection establishment, reading, and writing.
5. Cleanup by calling the ``HTTPClient/shutdown() [96AYW]`` method on the HTTPClient instance.

Please be aware that it is essential to properly terminate the HTTP client after executing requests. Forgetting to invoke the ``HTTPClient/shutdown() [96AYW]`` method may cause the library to issue a warning about a potential memory leak when compiling the application in debug mode.


## Performing HTTP requests

An HTTP request includes the method, a URL, headers providing supplementary details, and optionally, a body containing data transmitted to the server. Conversely, HTTP responses contain a status code, headers providing further details, and a body containing the actual content of the response. Together, these components facilitate the exchange of data between clients and servers over the HTTP protocol.

Below is an illustration of how to employ the HTTP request and response objects using the AsyncHTTPClient library in Swift:

@Snippet(id: async-http-client-02)

1. A new ``HTTPClientRequest`` object is created targeting the specified URL.
2. The HTTP request method is set to POST.
3. A `user-agent` header with the value `"Swift AsyncHTTPClient"` is added to the request.
4. The request body is set to contain the string "Some data".
5. The request is executed with a custom timeout of 5 seconds.
6. If the response status is `.ok` (`200`), further processing is performed.
7. The `content-type` of the response is retrieved from the headers.
8. The response body is collected asynchronously into a ``ByteBuffer``, up to a maximum of 1 MiB in size.
9. The raw response body is converted into a ``String`` for further processing.

Any errors encountered during the execution of the request are caught and printed. If the response body exceeds the 1 MiB limit, a ``NIOTooManyBytesError`` error will occur.

Finally, the HTTP client is shut down to release associated resources.

## JSON requests

JSON requests involve sending and receiving data formatted in JSON to a server. REST API is a style for building networked apps where resources are managed using regular HTTP methods, and the data is encoded and decoded using the JSON format.

The following code snippet demonstrates how to encode request bodies and decode response bodies using JSON objects:

@Snippet(id: async-http-client-03)

1. Two ``Codable`` structures are defined: `Input` for the data to be sent and `Output` for receiving the JSON response.
2. An HTTP request is created using a POST method and a `content-type: application/json` header.
3. The `Input` data is encoded into JSON data using a ``ByteBuffer`` and set as the request body.
4. If the response status is ok and the content type is JSON, the response body is processed.
5. The response body chunks are collected asynchronously using ``AsyncSequence.collect(upTo:)``
6. The buffer containing the JSON data response is decoded as an `Output` structure using ``JSONDecoder.decode(_:from:) [7481W]``.

The code snippet above demonstrates how to use Swift's Codable protocol to handle JSON data in HTTP communication. It defines structures for input and output data, sends a POST request with JSON payload, and processes the response by decoding JSON into a designated output structure.

## File downloads

The AsyncHTTPClient library provides support for file downloads using the ``FileDownloadDelegate``. This feature enables asynchronous streaming of downloaded data while simultaneously reporting the download progress, as demonstrated in the following example:

@Snippet(id: async-http-client-04)

1. A ``FileDownloadDelegate`` is created to manage file downloads. 
2. Specify the download destination path.
3. A progress reporting function is provided to monitor the download progress.
4. The file download request is executed using the request URL and the delegate.

Running this example will display the download progress, indicating the received bytes and the total bytes, with the same information also available within the `fileDownloadResponse` object. 

There are many more configuration options available for the Swift AsyncHTTPClient library. It is also possible to create custom delegate objects; additional useful examples and code snippets are provided in the project's [README on GitHub](https://github.com/swift-server/async-http-client).

