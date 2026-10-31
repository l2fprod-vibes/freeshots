// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Freeshots",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "Freeshots",
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
    ]
)
