// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GridStack",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "GridStack", targets: ["GridStack"])
    ],
    targets: [
        .executableTarget(
            name: "GridStack",
            path: "Sources",
            resources: []
        ),
        .testTarget(
            name: "GridStackTests",
            dependencies: ["GridStack"],
            path: "Tests"
        )
    ]
)
