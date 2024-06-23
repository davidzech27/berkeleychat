// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "BerkeleychatServer",
    platforms: [
        .macOS(.v12),
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift", from: "1.23.0"),
        .package(url: "https://github.com/swift-server/RediStack.git", from: "1.6.2"),
        .package(url: "https://github.com/soto-project/soto.git", from: "6.8.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "BerkeleychatServer",
            dependencies: [
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "RediStack", package: "RediStack"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ],
            path: "Sources"
        ),
    ]
)
