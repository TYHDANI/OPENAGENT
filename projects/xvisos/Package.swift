// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "{{APP_NAME}}",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "{{APP_NAME}}",
            targets: ["{{APP_NAME}}"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "{{APP_NAME}}",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "{{APP_NAME}}Tests",
            dependencies: [
                .byName(name: "{{APP_NAME}}")
            ],
            path: "Tests"
        )
    ]
)
