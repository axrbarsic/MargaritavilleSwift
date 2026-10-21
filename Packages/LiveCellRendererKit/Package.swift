// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LiveCellRendererKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LiveCellRendererKit",
            targets: ["LiveCellRendererKit"]
        )
    ],
    targets: [
        .target(
            name: "LiveCellRendererKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "LiveCellRendererKitTests",
            dependencies: ["LiveCellRendererKit"]
        )
    ]
)
