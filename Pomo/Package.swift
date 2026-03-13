// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pomo",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Pomo",
            path: "Sources",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "PomoTests",
            dependencies: ["Pomo"],
            path: "Tests"
        ),
    ]
)
