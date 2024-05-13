// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "site",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "SiteBuilder", targets: ["SiteBuilder"]),
        .library(name: "__SwiftOnServer_org", targets: ["__SwiftOnServer_org"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams", from: "5.1.2"),
        .package(url: "https://github.com/hummingbird-project/swift-mustache", from: "2.0.0-beta.1"),
        .package(url: "https://github.com/BinaryBirds/file-manager-kit", from: "0.1.0"),

        // article dependencies
        .package(url: "https://github.com/hummingbird-project/hummingbird", from: "2.0.0-beta.4"),
        //  .package(url: "https://github.com/hummingbird-project/swift-mustache", from: "2.0.0-beta.1"),
        .package(url: "https://github.com/swift-server/async-http-client", from: "1.21.1"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.65.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.5.4"),
    ],
    targets: [
        .target(
            name: "__SwiftOnServer_org",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .executableTarget(
            name: "SiteBuilder",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "Mustache", package: "swift-mustache"),
                .product(name: "FileManagerKit", package: "file-manager-kit"),
            ]
        ),
    ]
)
