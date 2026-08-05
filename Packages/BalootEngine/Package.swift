// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BalootEngine",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "BalootEngine", targets: ["BalootEngine"])
    ],
    targets: [
        .target(
            name: "BalootEngine",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "BalootEngineTests",
            dependencies: ["BalootEngine"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
