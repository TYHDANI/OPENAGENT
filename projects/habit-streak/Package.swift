// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "StreamFlow",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "StreamFlow",
            targets: ["StreamFlow"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "StreamFlow",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "StreamFlowTests",
            dependencies: [
                .byName(name: "StreamFlow")
            ],
            path: "Tests"
        )
    ]
)
