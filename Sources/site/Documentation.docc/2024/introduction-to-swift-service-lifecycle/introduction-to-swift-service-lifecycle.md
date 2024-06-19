# Introduction to Swift Service Lifecycle

The [Swift Service Lifecycle](https://github.com/swift-server/swift-service-lifecycle) library helps to manage application lifecycle by providing a unified start and stop mechanism. It also features a signal-based shutdown hook, allowing users to gracefully shut down and clean up resources before the application exits.


## A basic service example

First, the Swift Service Lifecycle package needs to be added to the project. This can be done by modifying the `Package.swift` file as follows:

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Example",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "Example",
            dependencies: [
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
            ]
        ),
    ]
)
```

Before the actual implementation, it is important to understand the basic building blocks of the Service Lifecycle library.

Long-running work should be modeled as services that implement the ``Service`` protocol. This protocol requires only one function: a simple asynchronous throwing ``run()`` method.

The ``ServiceGroup`` is used to orchestrate multiple services. A child task is spawned for each service, and the respective run method is called in the child task. Additionally, signal listeners are set up for the configured signals, triggering a graceful shutdown for each service.

A ``ServiceGroup`` manages the execution of multiple services, handles signal processing, and signals graceful shutdowns to the services. 

While a service is typically a long-running task, it can also be a simple task that returns immediately. By default, if one service returns or throws an error, the entire group is canceled. This behavior can be customized by providing a custom ``successTerminationBehavior`` parameter for the service group, as detailed [here](https://swiftpackageindex.com/swift-server/swift-service-lifecycle/main/documentation/servicelifecycle/how-to-adopt-servicelifecycle-in-applications#Customizing-the-behavior-when-a-service-returns-or-throws).

The following example illustrates a simple service and a service group with customized termination behavior:

```swift
import ServiceLifecycle

struct BasicService: Service {
    // 1.
    func run() async throws {
        print("Hello, basic service!")
    }
}

@main
struct Application {

    static func main() async throws {
        // 2.
        let service = BasicService()

        // 3.
        let serviceGroup = ServiceGroup(
            configuration: .init(
                services: [
                    // 4.
                    .init(
                        service: service,
                        successTerminationBehavior: .ignore,
                    )
                ],
                logger: .init(
                    label: "service-group"
                )
            )
        )
        // 5.
        try await serviceGroup.run()
    }
}
```

1. This is the implementation of the run function required by the ``Service`` protocol.
2. The `BasicService` instance is created, it's going to be used in the group.
3. A ``ServiceGroup`` is initialized with the service instances, using a custom configuration.
4. The service group configuration ignores service termination behavior for the basic service.
5. The `serviceGroup.run()` method is called to run the service group, with the configured services.

## Graceful shutdown and cancellation signals

Rather than setting a custom termination behavior, it is also possible to wait for a cancellation signal and then shut down service resources when that event occurs. The ``gracefulShutdown()`` function is designed to suspend the caller until a graceful shutdown is initiated. 

A graceful shutdown is when an application closes down in an orderly way. Instead of stopping suddenly, it finishes its current tasks and cleans up resources like open files or network connections. This matters because it prevents data loss, avoids corruption, and ensures that the system remains stable and reliable. By shutting down gracefully, applications can stop safely without causing problems for users or other systems they interact with.

The following code snippet illustrates this approach:

```swift
import ServiceLifecycle

struct BasicService: Service {

    func run() async throws {
        print("Start - basic service!")
       
        // 1. 
        try? await gracefulShutdown()
        
        print("Shutdown - basic service!")
    }
}

@main
struct Application {

    static func main() async throws {
        let service = BasicService()

        let serviceGroup = ServiceGroup(
            configuration: .init(
                services: [
                    // 2.
                    .init(service: service)
                ],
                // 3.
                cancellationSignals: [.sigterm, .sigint],
                logger: .init(
                    label: "service-group"
                )
            )
        )
        try await serviceGroup.run()
    }
}
```

1. Ignore cancellation error, waits for the service until it's cancelled
2. Configure the service using the default success termination behavior
3. Set the cancellation signals to `SIGTERM` & `SIGINT`

Run the application from the command line with the following command:

```sh
swift run
```

To halt execution and send a `SIGINT` signal to the application, press `CTRL+C`. Any code following the ``gracefulShutdown()`` function call within the run method will be executed upon receiving any of the cancellation signals.

## Service composition

It's feasible to utilize one service within another. For instance, we could create an asynchronous HTTP client-based service, potentially with a pool of HTTP clients. The provided code snippet demonstrates this concept:

```swift
import ServiceLifecycle
import AsyncHTTPClient

// 1.
actor AsyncHTTPClientService: Service {
    
    var httpClient: HTTPClient
    
    init() {
        self.httpClient = .init(
            eventLoopGroupProvider: .singleton
        )
    }

    func run() async throws {
        try? await gracefulShutdown()
        
        print("Shutting down http client service...")
        try await httpClient.shutdown()
    }
}

actor PingService: Service {
    
    let httpClientService: AsyncHTTPClientService
    
    // 2.
    init(httpClientService: AsyncHTTPClientService) {
        self.httpClientService = httpClientService
    }
    
    func run() async throws {
        // 3.
        try await withGracefulShutdownHandler {
            var i = 0
            // 4.
            repeat {
                print("Ping #\(i) - apple.com")
                
                let request = HTTPClientRequest(
                    url: "https://apple.com/"
                )

                // 5.
                let response = try await httpClientService.httpClient.execute(
                    request,
                    timeout: .seconds(1)
                )

                if response.status == .ok {
                    print("Ping #\(i) - ok")
                }
                else {
                    print("Ping #\(i) - error")
                }

                // 6.
                try await Task.sleep(for: .seconds(1))
                i += 1
            } while i < 2
        } onGracefulShutdown: {
            // 7.
            print("Shutting down ping service...")
        }
    }
}

@main
struct Application {

    static func main() async throws {
        // 8.
        let httpClientService = AsyncHTTPClientService()
        let pingService = PingService(httpClientService: httpClientService)

        // 9.
        let serviceGroup = ServiceGroup(
            configuration: .init(
                services: [
                    .init(
                        service: httpClientService,
                        successTerminationBehavior: .ignore,
                        failureTerminationBehavior: .gracefullyShutdownGroup
                    ),
                    .init(
                        service: pingService,
                        successTerminationBehavior: .gracefullyShutdownGroup,
                        failureTerminationBehavior: .gracefullyShutdownGroup
                    ),
                ],
                logger: .init(label: "service-group")
            )
        )
        
        try await serviceGroup.run()
    }
}
```

1. Defines an `AsyncHTTPClientService` actor that initializes an HTTP client and implements the run method to handle graceful shutdown by shutting down the HTTP client.
2. Defines a `PingService` actor that relies on the `AsyncHTTPClientService` for making HTTP requests.
3. Uses ``withGracefulShutdownHandler`` to handle graceful shutdown within the `PingService` actor's run method.
4. Initiates a loop for sending HTTP requests to apple.com and prints the result.
5. Executes an HTTP request asynchronously using the AsyncHTTPClientService and handles the response.
6. Delays execution for one second before the next iteration of the loop.
7. Defines a closure to be executed on graceful shutdown within the `PingService` actor.
8. In the `Application` struct's main function, initializes the `AsyncHTTPClientService` and `PingService`, and creates a ``ServiceGroup`` to manage their lifecycles.
9. Configures the ``ServiceGroup`` with appropriate termination behaviors for each service and initiates its execution.


## Conclusion

In summary, Swift Service Lifecycle simplifies application startup and shutdown, ensuring efficient resource management. It encapsulates critical startup and shutdown workflows in a reusable, framework-agnostic manner, enhancing application robustness.

The library's seamless integration with Structured Concurrency simplifies the management of concurrent tasks, including first-class support for async sequences and facilitating efficient resource utilization.

The detailed documentation, intended for both [application](https://swiftpackageindex.com/swift-server/swift-service-lifecycle/main/documentation/servicelifecycle/how-to-adopt-servicelifecycle-in-applications) and [library](https://swiftpackageindex.com/swift-server/swift-service-lifecycle/main/documentation/servicelifecycle/how-to-adopt-servicelifecycle-in-libraries) developers, includes examples demonstrating how to use the features, which helps developers grasp the core concepts of the Swift Service Lifecycle library.

