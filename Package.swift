// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DelayedCmdQ",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "DelayedCmdQKit",
            path: "Sources/DelayedCmdQKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "DelayedCmdQ",
            dependencies: ["DelayedCmdQKit"],
            path: "Sources/DelayedCmdQ",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "DelayedCmdQKitTests",
            dependencies: ["DelayedCmdQKit"],
            path: "Tests/DelayedCmdQKitTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
