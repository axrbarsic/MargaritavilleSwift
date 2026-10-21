// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BrooklynWebBackgroundKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "BrooklynWebBackgroundKit",
            targets: ["BrooklynWebBackgroundKit"]
        )
    ],
    targets: [
        .target(
            name: "BrooklynWebBackgroundKit",
            resources: [.copy("Resources/WebDist")]
        ),
        .testTarget(
            name: "BrooklynWebBackgroundKitTests",
            dependencies: ["BrooklynWebBackgroundKit"]
        )
    ]
)
