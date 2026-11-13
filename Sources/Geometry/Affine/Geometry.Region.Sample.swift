#if Affine
    public import Vector

    extension Geometry.Region {

        /// A region's signed distance at a point, and its gradient there: the unit direction in which the
        /// distance grows fastest, away from the region, or zero where there is no one such direction.
        public struct Sample {

            public var distance: Scalar

            public var gradient: Vector::Vector<2, Scalar>

            @inlinable
            public init(distance: Scalar, gradient: Vector::Vector<2, Scalar>) {
                self.distance = distance
                self.gradient = gradient
            }
        }
    }

    extension Geometry.Region.Sample: Sendable where Scalar: Sendable {}
    extension Geometry.Region.Sample: Equatable where Scalar: Equatable {}
    extension Geometry.Region.Sample: Hashable where Scalar: Hashable {}

    extension Geometry.Region.Sample where Scalar: BinaryFloatingPoint {

        @inlinable
        init(distance: Scalar, x: Scalar, y: Scalar) {
            self.init(distance: distance, gradient: Vector::Vector<2, Scalar>([x, y]))
        }

        /// The sample of the union of two regions whose boundaries are joined by a rounded neck within `radius`:
        /// the smooth minimum of the distances, b + (a − b)·h − radius·h·(1 − h) with
        /// h = ½ + (b − a) / (2·radius) held to 0…1, and its gradient, the gradients mixed by h. Where the
        /// distances differ by at least the radius it is the plain minimum, bit for bit; it is never above that
        /// minimum and at most a quarter of the radius below it, and continuous with its gradient. A radius that
        /// is not positive gives the plain minimum.
        @inlinable
        public func joined(with other: Self, radius: Scalar) -> Self {
            let a = distance
            let b = other.distance
            guard radius > 0, radius.isFinite, abs(a - b) < radius else { return a <= b ? self : other }
            let h = Swift.min(Swift.max(0.5 + (b - a) / (2 * radius), 0), 1)
            let joined = b + (a - b) * h - radius * h * (1 - h)
            let x = other.gradient[0] + (gradient[0] - other.gradient[0]) * h
            let y = other.gradient[1] + (gradient[1] - other.gradient[1]) * h
            return Self(distance: joined, gradient: Vector::Vector<2, Scalar>([x, y]))
        }
    }
#endif
