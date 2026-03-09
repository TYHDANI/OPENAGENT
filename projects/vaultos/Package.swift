// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VaultOS",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "VaultOS", targets: ["VaultOS"])
    ],
    targets: [
        .target(name: "VaultOS", path: "Sources"),
        .testTarget(name: "VaultOSTests", dependencies: ["VaultOS"], path: "Tests")
    ]
)
