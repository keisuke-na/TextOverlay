// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TextOverlayFeature",
    platforms: [.macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TextOverlayFeature",
            targets: ["TextOverlayFeature"]
        ),
        .library(
            name: "SwiftConfetti",
            targets: ["SwiftConfetti"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TextOverlayFeature",
            dependencies: ["SwiftConfetti"],
            swiftSettings: [
                .unsafeFlags(["-framework", "SpriteKit"])
            ]
        ),
        .target(
            name: "SwiftConfetti"
        ),
        .testTarget(
            name: "TextOverlayFeatureTests",
            dependencies: [
                "TextOverlayFeature"
            ]
        ),
    ]
)
