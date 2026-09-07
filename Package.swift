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
        .library(name: "Geometry", targets: ["Geometry"]),
        .library(name: "Geometry Standard Library Integration", targets: ["Geometry Standard Library Integration"]),
        .library(name: "Geometry Foundation Library Integration", targets: ["Geometry Foundation Library Integration"]),
        .library(name: "Geometry Test Support", targets: ["Geometry Test Support"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-linear.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-affine.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-spatial.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-scale.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-numeric.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-tagged.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Geometry",
            dependencies: [
                .product(name: "Linear", package: "swift-linear"),
                .product(name: "Spatial", package: "swift-spatial"),
                .product(name: "Scale", package: "swift-scale"),
                .product(name: "Numeric", package: "swift-numeric"),
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            path: "Sources/Geometry"
        ),
        .target(
            name: "Geometry Standard Library Integration",
            dependencies: [
                .target(name: "Geometry"),
            ],
            path: "Sources/Geometry Standard Library Integration"
        ),
        .target(
            name: "Geometry Foundation Library Integration",
            dependencies: [
                .target(name: "Geometry"),
                .target(name: "Geometry Standard Library Integration"),
            ],
            path: "Sources/Geometry Foundation Library Integration"
        ),
        .target(
            name: "Geometry Test Support",
            dependencies: [
                .target(name: "Geometry"),
                .product(name: "Affine Test Support", package: "swift-affine"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Geometry Tests",
            dependencies: [
                .target(name: "Geometry"),
                .target(name: "Geometry Test Support"),
                .target(name: "Geometry Standard Library Integration"),
                .target(name: "Geometry Foundation Library Integration"),
            ],
            path: "Tests/Geometry Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    target.swiftSettings = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
