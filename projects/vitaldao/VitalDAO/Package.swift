// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VitalDAO",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .macCatalyst(.v17)
    ],
    products: [
        .library(name: "VitalDAO", targets: ["VitalDAO"])
    ],
    targets: [
        .target(
            name: "VitalDAO",
            path: "Sources"
        )
    ]
)
