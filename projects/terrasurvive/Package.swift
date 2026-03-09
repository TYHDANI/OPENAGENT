// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TerraSurvive",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TerraSurvive", targets: ["TerraSurvive"])
    ],
    targets: [
        .executableTarget(
            name: "TerraSurvive",
            path: "Sources"
        ),
        .testTarget(
            name: "TerraSurviveTests",
            dependencies: ["TerraSurvive"],
            path: "Tests"
        )
    ]
)
