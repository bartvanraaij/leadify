// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LeadifyCore",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .library(name: "LeadifyCore", targets: ["LeadifyCore"]),
    ],
    targets: [
        .target(
            name: "LeadifyCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "LeadifyCoreTests",
            dependencies: ["LeadifyCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
