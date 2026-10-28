// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pulse",
    platforms: [.macOS(.v14)],
    targets: [
        // Pure logic: traffic counters, rate math, formatting, preferences.
        .target(name: "PulseCore"),
        // Drawing of the menu bar label.
        .target(name: "PulseUI", dependencies: ["PulseCore"]),
        // The menu bar app itself.
        .executableTarget(name: "Pulse", dependencies: ["PulseCore", "PulseUI"]),
        // Renders all display modes to a PNG for design review.
        .executableTarget(name: "PulsePreview", dependencies: ["PulseCore", "PulseUI"]),
        .testTarget(name: "PulseCoreTests", dependencies: ["PulseCore"]),
        .testTarget(name: "PulseUITests", dependencies: ["PulseUI"]),
    ]
)
