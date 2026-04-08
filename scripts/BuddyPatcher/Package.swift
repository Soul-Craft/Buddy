// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BuddyPatcher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "buddy-patcher",
            path: "Sources/BuddyPatcher"
        ),
    ]
)
