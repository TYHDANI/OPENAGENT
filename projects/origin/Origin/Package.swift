// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Origin",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Origin",
            targets: ["Origin"]
        )
    ],
    targets: [
        .target(
            name: "Origin",
            path: "Sources"
        )
    ]
)
