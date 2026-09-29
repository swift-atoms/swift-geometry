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
    traits: [
        .trait(name: "Affine", description: "Affine integration"),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-inset.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-vector.git", branch: "main"),
        .package(
            url: "https://github.com/swift-atoms/swift-linear.git",
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
            url: "https://github.com/swift-atoms/swift-quantizer.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-tagged.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-atoms/swift-affine.git", branch: "main", traits: [.trait(name: "Tagged", condition: .when(traits: ["Affine"])), .trait(name: "Vector", condition: .when(traits: ["Affine"]))]),
        .package(url: "https://github.com/swift-atoms/swift-point.git", branch: "main", traits: [.trait(name: "Affine", condition: .when(traits: ["Affine"]))]),
        .package(url: "https://github.com/swift-atoms/swift-coordinate.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-displacement.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-translation.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-segment.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-orthotope.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-size.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-magnitude.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-angle.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-trigonometry.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-numeric.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Geometry",
            dependencies: [
                .product(name: "Linear", package: "swift-linear"),
                .product(name: "Vector", package: "swift-vector"),
                .product(name: "Inset", package: "swift-inset"),
                .product(name: "Spatial", package: "swift-spatial"),
                .product(name: "Scale", package: "swift-scale"),
                .product(name: "Quantizer", package: "swift-quantizer"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Affine", package: "swift-affine", condition: .when(traits: ["Affine"])),
                .product(name: "Point", package: "swift-point", condition: .when(traits: ["Affine"])),
                .product(name: "Coordinate", package: "swift-coordinate", condition: .when(traits: ["Affine"])),
                .product(name: "Displacement", package: "swift-displacement", condition: .when(traits: ["Affine"])),
                .product(name: "Translation", package: "swift-translation", condition: .when(traits: ["Affine"])),
                .product(name: "Segment", package: "swift-segment", condition: .when(traits: ["Affine"])),
                .product(name: "Orthotope", package: "swift-orthotope", condition: .when(traits: ["Affine"])),
                .product(name: "Size", package: "swift-size", condition: .when(traits: ["Affine"])),
                .product(name: "Magnitude", package: "swift-magnitude", condition: .when(traits: ["Affine"])),
                .product(name: "Angle", package: "swift-angle", condition: .when(traits: ["Affine"])),
                .product(name: "Trigonometry", package: "swift-trigonometry", condition: .when(traits: ["Affine"])),
                .product(name: "Numeric", package: "swift-numeric", condition: .when(traits: ["Affine"])),
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
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Geometry Tests",
            dependencies: [
                .target(name: "Geometry"),
            ],
            path: "Tests/Geometry Tests"
        ),
        .testTarget(name: "Geometry Affine Integration Tests", dependencies: [.target(name: "Geometry"), .target(name: "Geometry Test Support"), .product(name: "Affine", package: "swift-affine", condition: .when(traits: ["Affine"])), .product(name: "Spatial", package: "swift-spatial", condition: .when(traits: ["Affine"])), .product(name: "Linear", package: "swift-linear", condition: .when(traits: ["Affine"])), .product(name: "Numeric", package: "swift-numeric", condition: .when(traits: ["Affine"])), .product(name: "Quantizer", package: "swift-quantizer", condition: .when(traits: ["Affine"])), .product(name: "Scale", package: "swift-scale", condition: .when(traits: ["Affine"])), .product(name: "Displacement", package: "swift-displacement", condition: .when(traits: ["Affine"])), .product(name: "Vector", package: "swift-vector", condition: .when(traits: ["Affine"])), .product(name: "Segment", package: "swift-segment", condition: .when(traits: ["Affine"]))], path: "Tests/Geometry Affine Integration Tests"),
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
