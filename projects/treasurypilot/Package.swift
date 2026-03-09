// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TreasuryPilot",
    platforms: [
        .iOS(.v17)
    ],
    targets: [
        .executableTarget(
            name: "TreasuryPilot",
            path: "Sources"
        ),
        .testTarget(
            name: "TreasuryPilotTests",
            dependencies: [
                .byName(name: "TreasuryPilot")
            ],
            path: "Tests"
        )
    ]
)
