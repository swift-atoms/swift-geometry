#if Affine
    public import Numeric

    extension Geometry {

        /// A rectangle whose corners are quarters of a superellipse: within `radius` of each corner along both
        /// sides the boundary is the quarter of |x|ⁿ + |y|ⁿ = rⁿ about the point `radius` in from both sides, for n
        /// the `exponent`. With an exponent of 2 the corners are circular arcs; above 2 a corner meets its sides
        /// with no curvature, so the outline's curvature grows from zero along the corner and back, the
        /// continuous corner of industrial design (about 5 reads like it). The radius is held to 0 up to half the
        /// shorter side, and an exponent below 1 counts as 1.
        public struct Superellipse {

            public var rectangle: Geometry.Rectangle

            public var radius: Scalar

            public var exponent: Scalar

            @inlinable
            public init(_ rectangle: Geometry.Rectangle, radius: Scalar, exponent: Scalar) {
                self.rectangle = rectangle
                self.radius = radius
                self.exponent = exponent
            }
        }
    }

    extension Geometry.Superellipse: Sendable where Scalar: Sendable {}
    extension Geometry.Superellipse: Equatable where Scalar: Equatable {}
    extension Geometry.Superellipse: Hashable where Scalar: Hashable {}

    extension Geometry.Superellipse where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// The signed distance at a point, negative inside, and its gradient: the unit normal of the level set
        /// through the point, which on the boundary is the distance's rate of change. Along the straight sides it is
        /// the distance to the side exactly. In a corner it is f / |∇f| for f = ‖q‖ₙ − r, the n-norm of the point's
        /// place q from the corner's centre less the radius: zero exactly on the boundary, equal to the distance
        /// there to first order, and continuous with its gradient where the corner meets its sides. At an exponent
        /// of 2 it is the exact distance of a rectangle with rounded corners. The corner's gradient is
        /// ∇f = (qx^(n−1), qy^(n−1)) / ‖q‖ₙ^(n−1).
        @inlinable
        public func sample(_ x: Scalar, _ y: Scalar) -> Geometry.Region.Sample {
            let left = Swift.min(rectangle.llx.underlying, rectangle.urx.underlying)
            let right = Swift.max(rectangle.llx.underlying, rectangle.urx.underlying)
            let top = Swift.min(rectangle.lly.underlying, rectangle.ury.underlying)
            let bottom = Swift.max(rectangle.lly.underlying, rectangle.ury.underlying)
            let half = ((right - left) / 2, (bottom - top) / 2)
            let round = Swift.min(Swift.max(radius.isNaN ? 0 : radius, 0), Swift.min(half.0, half.1))
            let n = Swift.max(exponent.isNaN ? 2 : exponent, 1)
            let dx = x - (left + right) / 2
            let dy = y - (top + bottom) / 2
            let sx: Scalar = dx < 0 ? -1 : 1
            let sy: Scalar = dy < 0 ? -1 : 1
            let qx = abs(dx) - (half.0 - round)
            let qy = abs(dy) - (half.1 - round)
            guard qx > 0, qy > 0, round > 0 else {
                return qx >= qy ? .init(distance: qx - round, x: sx, y: 0) : .init(distance: qy - round, x: 0, y: sy)
            }
            let scale = Swift.max(qx, qy)
            let ux = qx / scale
            let uy = qy / scale
            let px = Scalar.exp(n * Scalar.log(ux))
            let py = Scalar.exp(n * Scalar.log(uy))
            let norm = scale * Scalar.exp(Scalar.log(px + py) / n)
            let gx = px / ux
            let gy = py / uy
            let ratio = Scalar.exp((n - 1) * Scalar.log(norm / scale))
            let fx = gx / ratio
            let fy = gy / ratio
            let length = (fx * fx + fy * fy).squareRoot()
            guard length > 0, length.isFinite else { return .init(distance: norm - round, x: 0, y: 0) }
            return .init(distance: (norm - round) / length, x: sx * fx / length, y: sy * fy / length)
        }
    }

    extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// A superellipse's border as one closed subpath of straight pieces, counterclockwise from the lower end of
        /// its right side as `init(_:radius:)` runs a rectangle: the sides as they are, and each corner as k chords
        /// between points of its quarter at evenly spaced angles from the corner's centre, the point at angle θ
        /// lying r / ‖(cos θ, sin θ)‖ₙ from it, so every point is on the boundary that `sample(_:_:)` gives as 0.
        /// k is ⌈(π / 2)·√(n·r / (8·tolerance))⌉, at least 2 and at most 1024: about the count at which a chord
        /// strays from the quarter by the tolerance where it bends most. A corner of no radius is square.
        @inlinable
        public init(_ shape: Geometry.Superellipse, tolerance: Geometry.Length) {
            let rectangle = shape.rectangle
            let left = Swift.min(rectangle.llx.underlying, rectangle.urx.underlying)
            let right = Swift.max(rectangle.llx.underlying, rectangle.urx.underlying)
            let lower = Swift.min(rectangle.lly.underlying, rectangle.ury.underlying)
            let upper = Swift.max(rectangle.lly.underlying, rectangle.ury.underlying)
            let round = Swift.min(Swift.max(shape.radius.isNaN ? 0 : shape.radius, 0), Swift.min(right - left, upper - lower) / 2)
            let n = Swift.max(shape.exponent.isNaN ? 2 : shape.exponent, 1)
            let tolerance = tolerance.underlying > 0 ? tolerance.underlying : Scalar(1) / 100
            let wanted = Scalar.pi / 2 * (n * round / (8 * tolerance)).squareRoot()
            let count = wanted.isFinite ? Swift.min(Swift.max(Int(wanted.rounded(.up)), 2), 1024) : 2
            func at(_ x: Scalar, _ y: Scalar) -> Geometry.Point<2> {
                Geometry.Point(x: Geometry.X(x), y: Geometry.Y(y))
            }
            var points: [Geometry.Point<2>] = []
            func corner(_ x: Scalar, _ y: Scalar, from quarter: Int) {
                guard round > 0 else {
                    points.append(at(x, y))
                    return
                }
                for step in 0...count {
                    let angle = (Scalar(quarter) + Scalar(step) / Scalar(count)) * Scalar.pi / 2
                    let c = Scalar.cos(angle)
                    let s = Scalar.sin(angle)
                    let (ac, as_) = (abs(c), abs(s))
                    let largest = Swift.max(ac, as_)
                    func power(_ value: Scalar) -> Scalar { value > 0 ? Scalar.exp(n * Scalar.log(value / largest)) : 0 }
                    let norm = largest * Scalar.exp(Scalar.log(power(ac) + power(as_)) / n)
                    points.append(at(x + round * c / norm, y + round * s / norm))
                }
            }
            corner(right - round, lower + round, from: 3)
            corner(right - round, upper - round, from: 0)
            corner(left + round, upper - round, from: 1)
            corner(left + round, lower + round, from: 2)
            var segments: [Segment] = []
            for index in points.indices {
                let next = points[(index + 1) % points.count]
                guard points[index] != next else { continue }
                segments.append(.line(Geometry.Line.Segment(start: points[index], end: next)))
            }
            self.init(subpaths: [Subpath(startPoint: points[0], segments: segments, isClosed: true)])
        }
    }
#endif
