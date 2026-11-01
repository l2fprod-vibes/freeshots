// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Freeshots",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "FreeshotsCore"),
        .target(name: "FreeshotsRendering", dependencies: ["FreeshotsCore"], swiftSettings: [.defaultIsolation(MainActor.self)]),
        .executableTarget(
            name: "Freeshots",
            dependencies: ["FreeshotsCore", "FreeshotsRendering"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "FreeshotsCoreTests", dependencies: ["FreeshotsCore", "FreeshotsRendering"]),
    ]
)
