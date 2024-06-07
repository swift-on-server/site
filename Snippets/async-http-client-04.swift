import AsyncHTTPClient
import NIOCore
import Foundation

@main
struct Entrypoint {
    static func main() async throws {
        let httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton
        )

        do {
            // snippet.POINT
            let delegate = try FileDownloadDelegate(
                // 2.
                path: NSTemporaryDirectory() + "600x400.png",
                // 3.
                reportProgress: {
                    if let totalBytes = $0.totalBytes {
                        print("Total: \(totalBytes).")
                    }
                    print("Downloaded: \($0.receivedBytes).")
                }
            )

            // 4.
            let fileDownloadResponse = try await httpClient.execute(
                request: .init(
                    url: "https://placehold.co/600x400.png"
                ),
                delegate: delegate
            ).futureResult.get()

            print(fileDownloadResponse)
        } catch {
            print("\(error)")
        }

        try await httpClient.shutdown())
    }
}
