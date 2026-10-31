// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Freeshots",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "FreeshotsCore"),
        .executableTarget(
            name: "Freeshots",
            dependencies: ["FreeshotsCore"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "FreeshotsCoreTests", dependencies: ["FreeshotsCore"]),
    ]
)
