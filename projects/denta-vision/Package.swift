// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DentiMatch",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DentiMatch",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "DentiMatchTests",
            dependencies: ["DentiMatch"],
            path: "Tests"
        )
    ]
)
