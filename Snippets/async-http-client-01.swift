import AsyncHTTPClient
import NIOCore
import Foundation

@main
struct Entrypoint {
    static func main() async throws {
        let httpClient = HTTPClient(
            // 1.
            eventLoopGroupProvider: .singleton,
            // 2.
            configuration: .init(
                // 3.
                redirectConfiguration: .follow(
                    max: 3,
                    allowCycles: false
                ),
                // 4.
                timeout: .init(
                    connect: .init(.seconds(1)),
                    read: .seconds(1),
                    write: .seconds(1)
                )
            )
        )

        do {
            // perform HTTP operations
        } catch {
            print("\(error)")
        }

        // 5.
        try await httpClient.shutdown()
    }
}
