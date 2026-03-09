// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LegacyVault",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LegacyVault",
            targets: ["LegacyVault"]
        )
    ],
    targets: [
        .target(
            name: "LegacyVault",
            path: "Sources"
        ),
        .testTarget(
            name: "LegacyVaultTests",
            dependencies: [
                .byName(name: "LegacyVault")
            ],
            path: "Tests"
        )
    ]
)
