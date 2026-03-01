// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MicMute",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MicMute",
            path: "Sources/MicMute",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ServiceManagement"),
            ]
        )
    ]
)
