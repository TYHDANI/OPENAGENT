// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GEMOS",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "GEMOS",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "GEMOSTests",
            dependencies: ["GEMOS"],
            path: "Tests"
        )
    ]
)
