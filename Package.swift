// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FountainScenarioKit",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "FountainScenarioKit", targets: ["FountainScenarioKit"]),
        .library(name: "FountainScenarioTestKit", targets: ["FountainScenarioTestKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/midi2.git", exact: "0.9.1")
    ],
    targets: [
        .target(
            name: "FountainScenarioKit",
            dependencies: [.product(name: "MIDI2", package: "midi2")]
        ),
        .target(
            name: "FountainScenarioTestKit",
            dependencies: ["FountainScenarioKit"]
        ),
        .testTarget(
            name: "FountainScenarioKitTests",
            dependencies: ["FountainScenarioKit", "FountainScenarioTestKit"]
        )
    ]
)
