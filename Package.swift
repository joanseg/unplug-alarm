// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "UnplugAlarm",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "UnplugAlarm")
    ]
)
