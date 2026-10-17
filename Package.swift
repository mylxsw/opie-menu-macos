// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpieMenu",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "OpieMenu", targets: ["OpieMenu"]),
        .executable(name: "OpieNative", targets: ["OpieNative"])
    ],
    targets: [
        .target(name: "OpieMenu", path: "Packages/OpieMenu/Sources/OpieMenu"),
        .executableTarget(name: "OpieNative", dependencies: ["OpieMenu"], path: "Sources/OpieNative"),
        .testTarget(name: "OpieMenuTests", dependencies: ["OpieMenu"], path: "Packages/OpieMenu/Tests/OpieMenuTests")
    ]
)
