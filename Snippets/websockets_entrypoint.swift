import ArgumentParser
import Hummingbird

// 1.
protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
}

// 2.
@main
struct HummingbirdArguments: AppArguments, AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8080

    func run() async throws {
        // 3.
        let app = try await buildApplication(self)
        try await app.runService()
    }
}
