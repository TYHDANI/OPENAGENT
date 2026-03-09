// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AirScore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AirScore", targets: ["AirScore"])
    ],
    targets: [
        .target(name: "AirScore", path: "Sources"),
        .testTarget(name: "AirScoreTests", dependencies: ["AirScore"], path: "Tests")
    ]
)
