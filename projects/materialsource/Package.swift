// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MaterialSource",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "MaterialSource",
            targets: ["MaterialSource"]
        )
    ],
    dependencies: [
        // No third-party dependencies - using only Apple frameworks
    ],
    targets: [
        .executableTarget(
            name: "MaterialSource",
            dependencies: [],
            path: "Sources",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "MaterialSourceTests",
            dependencies: ["MaterialSource"],
            path: "Tests/MaterialSourceTests"
        )
    ]
)
