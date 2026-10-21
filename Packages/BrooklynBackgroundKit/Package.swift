// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BrooklynBackgroundKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "BrooklynBackgroundKit", targets: ["BrooklynBackgroundKit"])
    ],
    targets: [
        .target(
            name: "BrooklynBackgroundKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "BrooklynBackgroundKitTests",
            dependencies: ["BrooklynBackgroundKit"]
        )
    ]
)
