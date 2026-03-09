// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "YieldSentinel",
    platforms: [
        .iOS(.v17)
    ],
    targets: [
        .target(
            name: "YieldSentinel",
            path: "Sources"
        ),
        .testTarget(
            name: "YieldSentinelTests",
            dependencies: [
                .byName(name: "YieldSentinel")
            ],
            path: "Tests"
        )
    ]
)
