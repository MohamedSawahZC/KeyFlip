// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KeyFlip",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "KeyFlipCore"),
        .executableTarget(name: "KeyFlip", dependencies: ["KeyFlipCore"]),
        .testTarget(name: "KeyFlipCoreTests", dependencies: ["KeyFlipCore"]),
    ]
)
