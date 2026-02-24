// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "zeplin-cli",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "zeplin", targets: ["zeplin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "zeplin",
            dependencies: ["ZeplinCLI"]
        ),
        .target(
            name: "ZeplinCLI",
            dependencies: [
                "ZeplinKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "ZeplinKit"
        ),
        .testTarget(
            name: "ZeplinKitTests",
            dependencies: ["ZeplinKit"]
        ),
        .testTarget(
            name: "ZeplinCLITests",
            dependencies: [
                "ZeplinCLI",
                "ZeplinKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["ZeplinKit"]
        )
    ]
)
