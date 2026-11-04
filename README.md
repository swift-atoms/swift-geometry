# swift-geometry

Use this package when you compute with shapes in a coordinate space: points, lines, segments, rays, circles, ellipses, arcs, Bézier curves, polygons, rectangles and paths. Start from `Geometry<Scalar, Space>` and its nested types, such as `Geometry.Point`, `Geometry.Rectangle`, `Geometry.Polygon` and `Geometry.Path`. `Space` is a tag that keeps values from different spaces apart. The shapes come with the `Affine` trait; without it the package holds only sizes, depths and magnitudes. If you need bare points or vectors and no shapes, use swift-point or swift-linear.

## Laws

- The y axis points up. A rectangle is given by its lower-left and upper-right corners, `Geometry.Direction.up` is positive y, and a positive sweep or a positive signed area means counterclockwise.
- Nothing translates a shape implicitly. Translation takes an explicit `Affine` relationship, such as `Geometry.Point.cartesian`.
- A rectangle stores its center and half extents. With integer scalars, an odd width or height is rounded down to an even one.
- Rectangles, squares and circles contain the points on their boundary. `Geometry.Ball.containsInterior(_:)` excludes them. Rectangles that only touch intersect, and their intersection has zero width or height.
- `Geometry.Polygon.contains(_:)` and `Geometry.Ngon.contains(_:)` use the even-odd rule, so a point exactly on an edge can fall either way. `Geometry.Polygon.isOnBoundary(_:)` answers that case, within 100 times `ulpOfOne`.
- Parallel lines, rays and segments have no intersection. The test is exact, with no tolerance, and collinear overlapping segments have none either.
- `Geometry.Polygon.triangulate()` clips ears from counterclockwise vertices and stops when it finds none. Clockwise or self-intersecting input therefore gives fewer triangles than the vertex count minus two, possibly none.
- Converting an arc or an elliptical arc to Bézier curves gives one cubic segment per started quarter turn. A sweep of 2.5π gives five segments and ends at the arc's own end point.
- That conversion gives no segments when the start angle, end angle or sweep is not finite, when the sweep is zero, or when more than `Geometry.arcBezierSegmentLimit` segments (4096) would be needed. These checks run before anything is allocated.
- `Geometry.Ellipse.Arc.init(from:to:rx:ry:xAxisRotation:largeArcFlag:sweepFlag:)` follows SVG's endpoint form. Radii too small to reach both points are scaled up. Identical endpoints or a zero radius give an arc with zero sweep, which converts to no Bézier segments.
- A closed subpath converted to Bézier curves gets a closing line only when its last segment does not already end at the start point.
- `Geometry.Ball.bezierCurves` runs clockwise from the rightmost point of the circle. `Geometry.Bezier.approximating(_:)` runs counterclockwise from the same point.
- Bézier and elliptical arc lengths are measured along 100 straight pieces by default. An ellipse's perimeter uses Ramanujan's approximation.
