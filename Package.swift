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
            name: "Geometry Standard Library Integration",
            targets: ["Geometry Standard Library Integration"]
        ),
        .library(
            name: "Geometry Apple Foundation Integration",
            targets: ["Geometry Apple Foundation Integration"]
        ),
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
            url: "https://github.com/swift-atoms/swift-dimension.git",
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
                .product(name: "Affine", package: "swift-affine"),
                .product(name: "Dimension", package: "swift-dimension"),
                .product(name: "Numeric", package: "swift-numeric"),
                .product(
                    name: "Numeric Standard Library Integration",
                    package: "swift-numeric"
                ),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Geometry Standard Library Integration",
            dependencies: ["Geometry"]
        ),
        .target(
            name: "Geometry Apple Foundation Integration",
            dependencies: [
                "Geometry",
                "Geometry Standard Library Integration",
            ]
        ),
        .testTarget(
            name: "Geometry Tests",
            dependencies: [
                "Geometry",
                .product(name: "Affine", package: "swift-affine"),
                .product(name: "Dimension", package: "swift-dimension"),
                .product(name: "Linear", package: "swift-linear"),
                .product(name: "Numeric", package: "swift-numeric"),
                .product(
                    name: "Numeric Standard Library Integration",
                    package: "swift-numeric"
                ),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(
                    name: "Tagged Standard Library Integration",
                    package: "swift-tagged"
                ),
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
