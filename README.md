# swift-geometry

Coordinate-space-parameterized affine geometry — points, vectors, rectangles, and transforms — with compile-time space safety for Swift.

## Arc to Bézier conversion limits

`[Geometry.Bezier](arc:)` and `[Geometry.Bezier](ellipticalArc:)` emit one cubic segment per started quarter turn: the segment demand is `ceil(|sweep| / (π/2))`.

- The result is `[]` when the start angle, end angle or sweep is not finite (including a finite subtraction that overflows to infinity), when the sweep is zero or NaN, or when the segment demand exceeds `Geometry.arcBezierSegmentLimit` (4096). These checks run before any integer conversion or allocation.
- Within the limit, signed multi-turn sweeps are preserved, not clamped: a sweep of ±2.5π yields five segments and ends at the arc's own end point.

4096 is a resource policy limit, not a mathematical or performance guarantee.
