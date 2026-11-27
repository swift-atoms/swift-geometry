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
        .library(name: "Geometry Boundary", targets: ["Geometry Boundary"]),
    ],
    traits: [
        .trait(name: "Boundary", description: "Boundary integration", enabledTraits: ["Affine"]),
        .trait(name: "Affine", description: "Affine integration")
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-inset.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-vector.git", branch: "main"),
        .package(
            url: "https://github.com/swift-atoms/swift-linear.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-space.git",
            branch: "main",
            traits: ["Quantizer", "Scale"]
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
        .package(
            url: "https://github.com/swift-atoms/swift-affine.git",
            branch: "main",
            traits: [.trait(name: "Tagged", condition: .when(traits: ["Affine"])), .trait(name: "Vector", condition: .when(traits: ["Affine"]))]
        ),
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
        .package(url: "https://github.com/swift-atoms/swift-matrix.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-direction.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-cardinal.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-boundary.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Geometry",
            dependencies: [
                .product(name: "Linear", package: "swift-linear"),
                .product(name: "Vector", package: "swift-vector"),
                .product(name: "Inset", package: "swift-inset"),
                .product(name: "Space", package: "swift-space"),
                .product(name: "Scale", package: "swift-scale"),
                .product(name: "Quantizer", package: "swift-quantizer"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Affine", package: "swift-affine"),
                .product(name: "Point", package: "swift-point"),
                .product(name: "Coordinate", package: "swift-coordinate"),
                .product(name: "Displacement", package: "swift-displacement"),
                .product(name: "Translation", package: "swift-translation"),
                .product(name: "Segment", package: "swift-segment"),
                .product(name: "Orthotope", package: "swift-orthotope"),
                .product(name: "Size", package: "swift-size"),
                .product(name: "Magnitude", package: "swift-magnitude"),
                .product(name: "Angle", package: "swift-angle"),
                .product(name: "Trigonometry", package: "swift-trigonometry"),
                .product(name: "Numeric", package: "swift-numeric"),
                .product(name: "Matrix", package: "swift-matrix"),
                .product(name: "Direction", package: "swift-direction"),
                .product(name: "Cardinal", package: "swift-cardinal"),
            ],
            path: "Sources/Geometry"
        ),
        .target(
            name: "Geometry Standard Library Integration",
            dependencies: [
                .target(name: "Geometry")
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
                .target(name: "Geometry")
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Geometry Tests",
            dependencies: [
                .target(name: "Geometry")
            ],
            path: "Tests/Geometry Tests"
        ),
        .testTarget(
            name: "Geometry Affine Integration Tests",
            dependencies: [
                .target(name: "Geometry"), .target(name: "Geometry Test Support"), .product(name: "Affine", package: "swift-affine"),
                .product(name: "Space", package: "swift-space"), .product(name: "Linear", package: "swift-linear"),
                .product(name: "Numeric", package: "swift-numeric"),
                .product(name: "Quantizer", package: "swift-quantizer"), .product(name: "Scale", package: "swift-scale"),
                .product(name: "Displacement", package: "swift-displacement"),
                .product(name: "Vector", package: "swift-vector"), .product(name: "Segment", package: "swift-segment"),
                .product(name: "Matrix", package: "swift-matrix"), .product(name: "Direction", package: "swift-direction"),
                .product(name: "Cardinal", package: "swift-cardinal"),
            ],
            path: "Tests/Geometry Affine Integration Tests"
        ),
        .target(
            name: "Geometry Boundary",
            dependencies: [
                .target(name: "Geometry"),
                .product(name: "Boundary", package: "swift-boundary"),
            ]
        ),
        .testTarget(
            name: "Geometry Boundary Tests",
            dependencies: [
                .target(name: "Geometry Boundary"),
                .target(name: "Geometry"),
                .product(name: "Boundary", package: "swift-boundary"),
                .product(name: "Affine", package: "swift-affine"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
