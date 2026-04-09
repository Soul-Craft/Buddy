// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BuddyPatcher",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "BuddyPatcherLib",
            path: "Sources/BuddyPatcherLib"
        ),
        .executableTarget(
            name: "buddy-patcher",
            dependencies: ["BuddyPatcherLib"],
            path: "Sources/BuddyPatcher"
        ),
        .testTarget(
            name: "BuddyPatcherTests",
            dependencies: ["BuddyPatcherLib"],
            path: "Tests/BuddyPatcherTests"
        ),
    ]
)
