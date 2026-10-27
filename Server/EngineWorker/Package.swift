// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "BalootWorker", platforms: [.macOS(.v14)], dependencies: [.package(path: "../../Packages/BalootEngine")], targets: [.executableTarget(name: "BalootWorker", dependencies: [.product(name: "BalootEngine", package: "BalootEngine")])])
