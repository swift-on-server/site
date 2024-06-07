import AsyncHTTPClient
import NIOCore
import NIOFoundationCompat
import Foundation

// 1.
struct Input: Codable {
    let id: Int
    let title: String
    let completed: Bool
}

struct Output: Codable {
    let json: Input


@main
struct Entrypoint {
    static func main() async throws {
        let httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton
        )
        do {
            // 2.
            var request = HTTPClientRequest(
                url: "https://httpbin.org/post"
            )
            request.method = .POST
            request.headers.add(name: "content-type", value: "application/json")

            // 3.
            let input = Input(
                id: 1,
                title: "foo",
                completed: false
            )

            let encoder = JSONEncoder()
            let buffer = try encoder.encodeAsByteBuffer(input, allocator: ByteBufferAllocator())
            request.body = .bytes(buffer)

            let response = try await httpClient.execute(
                request,
                timeout: .seconds(5)
            )

            if response.status == .ok {
                // 4.
                if let contentType = response.headers.first(
                    name: "content-type"
                ), contentType.contains("application/json") {
                    // 5.
                    let buffer = try await response.body.collect(upTo: 1024 * 1024)

                    // 6.
                    let output = JSONDecoder().decode(Output.self, from: buffer)
                    print(output.json.title)
                }
            } else {
                print("Invalid status code: \(response.status)")
            }
        } catch {
            print("\(error)")
        }

        try await httpClient.shutdown()
    }
}
