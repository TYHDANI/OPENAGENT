// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Nighteye",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Nighteye", targets: ["Nighteye"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "Nighteye",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "NighteyeTests",
            dependencies: ["Nighteye"],
            path: "Tests"
        ),
    ]
)
