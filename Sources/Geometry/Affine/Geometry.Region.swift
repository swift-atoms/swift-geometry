#if Affine
    public import Direction
    public import Numeric
    import Point
    import Vector

    extension Geometry {

        /// A region of the plane known by its signed distance: how far a point lies outside its boundary,
        /// negative inside. A disc, a rectangle with rounded corners, the inside of a path, or a union of
        /// regions whose boundaries are joined by a rounded neck where they come close.
        public enum Region {

            /// The points of a circle.
            case ball(Geometry.Circle)

            /// The points of a rectangle with its corners rounded by a radius, held to 0 up to half its shorter
            /// side: a capsule at that half.
            case rectangle(Geometry.Rectangle, radius: Scalar)

            /// The points of a rectangle whose corners are quarters of a superellipse.
            case superellipse(Geometry.Superellipse)

            /// The points a path holds under the nonzero rule. Every segment counts as the line between its
            /// ends, so a path with curves is flattened first: `init(_:tolerance:)` does that.
            case path(Geometry.Path)

            /// The points of the regions, their boundaries joined where they come within `radius` of each other.
            case union([Region], radius: Scalar)
        }
    }

    extension Geometry.Region: Sendable where Scalar: Sendable {}
    extension Geometry.Region: Equatable where Scalar: Equatable {}
    extension Geometry.Region: Hashable where Scalar: Hashable {}

    extension Geometry.Region where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// The inside of a path under the nonzero rule, its curves flattened to within the tolerance.
        @inlinable
        public init(_ path: Geometry.Path, tolerance: Geometry.Length) throws(Geometry.Path.Error) {
            self = .path(try path.flattened(tolerance: tolerance))
        }

        /// A rectangle whose shorter sides are half circles.
        @inlinable
        public static func capsule(_ rectangle: Geometry.Rectangle) -> Self {
            let width = rectangle.urx.underlying - rectangle.llx.underlying
            let height = rectangle.ury.underlying - rectangle.lly.underlying
            return .rectangle(rectangle, radius: Swift.min(abs(width), abs(height)) / 2)
        }

        /// The signed distance at a point, and the way it grows fastest.
        @inlinable
        public func sample(at point: Geometry.Point<2>) -> Sample {
            sample(point[0], point[1])
        }

        /// The signed distance at a point: `sample(at:)`'s distance.
        @inlinable
        public func distance(to point: Geometry.Point<2>) -> Scalar {
            sample(point[0], point[1]).distance
        }

        @inlinable
        func sample(_ x: Scalar, _ y: Scalar) -> Sample {
            switch self {
            case .ball(let circle):
                let dx = x - circle.center[0]
                let dy = y - circle.center[1]
                let length = (dx * dx + dy * dy).squareRoot()
                let radius = circle.radius.underlying
                guard length > 0 else { return Sample(distance: -radius, x: 0, y: 0) }
                return Sample(distance: length - radius, x: dx / length, y: dy / length)

            case .rectangle(let rectangle, let radius):
                let left = Swift.min(rectangle.llx.underlying, rectangle.urx.underlying)
                let right = Swift.max(rectangle.llx.underlying, rectangle.urx.underlying)
                let top = Swift.min(rectangle.lly.underlying, rectangle.ury.underlying)
                let bottom = Swift.max(rectangle.lly.underlying, rectangle.ury.underlying)
                let half = ((right - left) / 2, (bottom - top) / 2)
                let round = Swift.min(Swift.max(radius.isNaN ? 0 : radius, 0), Swift.min(half.0, half.1))
                let dx = x - (left + right) / 2
                let dy = y - (top + bottom) / 2
                let sx: Scalar = dx < 0 ? -1 : 1
                let sy: Scalar = dy < 0 ? -1 : 1
                let qx = abs(dx) - (half.0 - round)
                let qy = abs(dy) - (half.1 - round)
                if qx > 0 || qy > 0 {
                    let ox = Swift.max(qx, 0)
                    let oy = Swift.max(qy, 0)
                    let length = (ox * ox + oy * oy).squareRoot()
                    return Sample(distance: length - round, x: sx * ox / length, y: sy * oy / length)
                }
                return qx >= qy ? Sample(distance: qx - round, x: sx, y: 0) : Sample(distance: qy - round, x: 0, y: sy)

            case .superellipse(let shape):
                return shape.sample(x, y)

            case .path(let path):
                var best = Scalar.infinity
                var foot = (x: x, y: y)
                func edge(from start: (x: Scalar, y: Scalar), to end: (x: Scalar, y: Scalar)) {
                    let run = (x: end.x - start.x, y: end.y - start.y)
                    let length = run.x * run.x + run.y * run.y
                    var t: Scalar = 0
                    if length > 0 { t = Swift.min(Swift.max(((x - start.x) * run.x + (y - start.y) * run.y) / length, 0), 1) }
                    let near = (x: start.x + t * run.x, y: start.y + t * run.y)
                    let distance = (x - near.x) * (x - near.x) + (y - near.y) * (y - near.y)
                    if distance < best {
                        best = distance
                        foot = near
                    }
                }
                for subpath in path.subpaths {
                    let first = (x: subpath.startPoint[0], y: subpath.startPoint[1])
                    var previous = first
                    for index in subpath.segments.indices {
                        guard let end = subpath.segments[index].endPoint else { continue }
                        let corner = (x: end[0], y: end[1])
                        edge(from: previous, to: corner)
                        previous = corner
                    }
                    edge(from: previous, to: first)
                }
                guard best.isFinite else { return Sample(distance: .infinity, x: 0, y: 0) }
                let length = best.squareRoot()
                let inside = path.contains(Geometry.Point<2>([x, y]), rule: .nonzero)
                let sign: Scalar = inside ? -1 : 1
                guard length > 0 else { return Sample(distance: 0, x: 0, y: 0) }
                return Sample(distance: sign * length, x: sign * (x - foot.x) / length, y: sign * (y - foot.y) / length)

            case .union(let regions, let radius):
                guard var total = regions.first?.sample(x, y) else { return Sample(distance: .infinity, x: 0, y: 0) }
                for region in regions.dropFirst() {
                    total = total.joined(with: region.sample(x, y), radius: radius)
                }
                return total
            }
        }

        /// A rectangle that holds every point at no positive distance, or nil for a region that holds none.
        @inlinable
        public var boundingBox: Geometry.Rectangle? {
            guard let box = bounds else { return nil }
            return Geometry.Rectangle(llx: .init(box.0), lly: .init(box.1), urx: .init(box.2), ury: .init(box.3))
        }

        @inlinable
        var bounds: (Scalar, Scalar, Scalar, Scalar)? {
            switch self {
            case .ball(let circle):
                let radius = abs(circle.radius.underlying)
                return (circle.center[0] - radius, circle.center[1] - radius, circle.center[0] + radius, circle.center[1] + radius)
            case .superellipse(let shape):
                let rectangle = shape.rectangle
                let xs = (rectangle.llx.underlying, rectangle.urx.underlying)
                let ys = (rectangle.lly.underlying, rectangle.ury.underlying)
                return (Swift.min(xs.0, xs.1), Swift.min(ys.0, ys.1), Swift.max(xs.0, xs.1), Swift.max(ys.0, ys.1))
            case .rectangle(let rectangle, _):
                let xs = (rectangle.llx.underlying, rectangle.urx.underlying)
                let ys = (rectangle.lly.underlying, rectangle.ury.underlying)
                return (Swift.min(xs.0, xs.1), Swift.min(ys.0, ys.1), Swift.max(xs.0, xs.1), Swift.max(ys.0, ys.1))
            case .path(let path):
                var box: (Scalar, Scalar, Scalar, Scalar)?
                for subpath in path.subpaths {
                    var points = [subpath.startPoint]
                    for segment in subpath.segments { if let end = segment.endPoint { points.append(end) } }
                    for point in points {
                        let old = box ?? (point[0], point[1], point[0], point[1])
                        box = (Swift.min(old.0, point[0]), Swift.min(old.1, point[1]), Swift.max(old.2, point[0]), Swift.max(old.3, point[1]))
                    }
                }
                return box
            case .union(let regions, let radius):
                var box: (Scalar, Scalar, Scalar, Scalar)?
                for region in regions {
                    guard let inner = region.bounds else { continue }
                    let old = box ?? inner
                    box = (Swift.min(old.0, inner.0), Swift.min(old.1, inner.1), Swift.max(old.2, inner.2), Swift.max(old.3, inner.3))
                }
                let grow = Swift.max(radius.isNaN ? 0 : radius, 0) / 4
                return box.map { ($0.0 - grow, $0.1 - grow, $0.2 + grow, $0.3 + grow) }
            }
        }
    }
#endif
