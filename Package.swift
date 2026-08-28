// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-geometry",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Geometry",
            targets: ["Geometry"]
        ),
        .library(
            name: "Geometry Test Support",
            targets: ["Geometry Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-linear.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-affine.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-affine-geometry.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-dimension.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-boundary.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-numeric.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-pair.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Geometry",
            dependencies: [
                .product(name: "Linear", package: "swift-linear"),
                .product(name: "Affine", package: "swift-affine"),
                .product(
                    name: "Affine Geometry",
                    package: "swift-affine-geometry"
                ),
                .product(name: "Dimension", package: "swift-dimension"),
                .product(name: "Boundary", package: "swift-boundary"),
                .product(name: "Real", package: "swift-numeric"),
                .product(name: "Pair", package: "swift-pair"),
            ]
        ),
        .target(
            name: "Geometry Test Support",
            dependencies: [
                "Geometry",
                .product(
                    name: "Affine Test Support",
                    package: "swift-affine"
                ),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Geometry Tests",
            dependencies: [
                "Geometry",
                "Geometry Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
