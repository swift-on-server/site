// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "site",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SiteBuilder", targets: ["SiteBuilder"]),
        .library(name: "__SwiftOnServer_org", targets: ["__SwiftOnServer_org"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.2"),
        .package(url: "https://github.com/hummingbird-project/swift-mustache.git", from: "2.0.0-beta.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "__SwiftOnServer_org"
        ),
        .executableTarget(
            name: "SiteBuilder",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "Mustache", package: "swift-mustache"),
            ]
        ),
    ]
)
