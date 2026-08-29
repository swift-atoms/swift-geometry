# Geometry

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Affine-independent geometry concepts built from linear, spatial, and numeric types. Point-backed shapes and transforms live in the separate `swift-geometry-affine-geometry` molecule package.

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-atoms/swift-geometry.git", branch: "main")
]
```

> Pre-1.0: no version tags yet. APIs may change; pin a commit for reproducible builds.

Add the atom product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Geometry", package: "swift-geometry")
    ]
)
```

For test targets, additionally depend on `Geometry Test Support`:

```swift
.testTarget(
    name: "YourTargetTests",
    dependencies: [
        .product(name: "Geometry", package: "swift-geometry"),
        .product(name: "Geometry Test Support", package: "swift-geometry")
    ]
)
```

Requires Swift 6.2+.

## License

Apache 2.0. See [LICENSE](LICENSE).
