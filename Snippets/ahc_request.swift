import AsyncHTTPClient
import NIOCore
import Foundation

// mark: hide
@main
struct Entrypoint {
    static func main() async throws {
        // snippet.show
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)

        do {
            // 1.
            var request = HTTPClientRequest(url: "https://httpbin.org/post")
            // 2.
            request.method = .POST
            // 3.
            request.headers.add(name: "User-Agent", value: "Swift AsyncHTTPClient")
            // 4.
            request.body = .bytes(ByteBuffer(string: "Some data"))

            // 5.
            let response = try await httpClient.execute(request, timeout: .seconds(5))

            // 6.
            if response.status == .ok {
                // 7.
                let contentType = response.headers.first(name: "content-type")

                // 8.
                let buffer = try await response.body.collect(upTo: 1024 * 1024)

                // 9.
                let rawResponseBody = String(buffer: buffer)

                print("Content Type", contentType ?? "unknown")
                print(rawResponseBody)
            }
        } catch {
            print("\(error)")
        }

        try await httpClient.shutdown()
        // snippet.hide
    }
}
