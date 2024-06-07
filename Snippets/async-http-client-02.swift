import AsyncHTTPClient
import NIOCore
import Foundation}

@main
struct Entrypoint {
    static func main() async throws {
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
                let contentLength = response.headers.first(
                    name: "content-length"
                ).flatMap(Int.init)

                // 9.
                let buffer = try await response.body.collect(upTo: 1024 * 1024)

                // 10.
                let rawResponseBody = String(buffer: buffer)

                print(rawResponseBody)
            }
        } catch {
            print("\(error)")
        }

        try await httpClient.shutdown()
    }
}
