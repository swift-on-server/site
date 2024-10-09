// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "cover-image-generator",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "cover-image-generator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "yams"),
            ],
            resources: [
                .copy("sots-horizontal.jpg"),
            ]
        ),
    ]
)
