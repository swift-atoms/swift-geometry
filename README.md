# Geometry

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Geometric primitives — composes affine, affine-geometry, algebra-linear, dimension, format, region, and numeric primitives. Ships an umbrella product plus a Test Support product for downstream test targets.

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-molecules/swift-geometry.git", branch: "main")
]
```

> Pre-1.0: no version tags yet. APIs may change; pin a commit for reproducible builds.

Add the umbrella product to your target:

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
