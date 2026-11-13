#if Affine
    public import Angle
    public import Cardinal
    import Point
    import Trigonometry

    public import Numeric

    extension Geometry {

        /// A regular star: `points` points at `outer` from its center and, halfway between each two, a notch
        /// at `inner`, joined by straight edges. The first point lies in the direction of the positive x axis
        /// from the center. With `inner` the cosine of half a point's share of the turn times `outer` it is
        /// the regular polygon of `points` sides.
        public struct Star {

            /// The middle of the star.
            public var center: Point<2>

            /// How many points it has, at least two.
            public let points: Cardinal

            /// The distance from the center to each point.
            public var outer: Radius

            /// The distance from the center to each notch between two points.
            public var inner: Radius

            /// A star of `points` points, at least two, around a center; nil for fewer.
            @inlinable
            public init?(points: Cardinal, outer: Radius, inner: Radius, at center: Point<2>) {
                guard points >= 2 else { return nil }
                self.center = center
                self.points = points
                self.outer = outer
                self.inner = inner
            }
        }
    }

    extension Geometry.Star: Sendable where Scalar: Sendable {}
    extension Geometry.Star: Equatable where Scalar: Equatable {}
    extension Geometry.Star: Hashable where Scalar: Hashable {}

    #if !hasFeature(Embedded)
        extension Geometry.Star: Codable where Scalar: Codable {
            private enum CodingKeys: String, CodingKey {
                case center, points, outer, inner
            }

            /// Decodes a star, failing for fewer than two points.
            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let points = Cardinal(try container.decode(UInt.self, forKey: .points))
                guard
                    let star = Self(
                        points: points,
                        outer: try container.decode(Geometry.Radius.self, forKey: .outer),
                        inner: try container.decode(Geometry.Radius.self, forKey: .inner),
                        at: try container.decode(Geometry.Point<2>.self, forKey: .center)
                    )
                else {
                    throw DecodingError.dataCorruptedError(forKey: .points, in: container, debugDescription: "A star has at least two points")
                }
                self = star
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(center, forKey: .center)
                try container.encode(points.rawValue, forKey: .points)
                try container.encode(outer, forKey: .outer)
                try container.encode(inner, forKey: .inner)
            }
        }
    #endif

    extension Geometry.Star where Scalar: AdditiveArithmetic {

        /// A star of `points` points, at least two, around the origin; nil for fewer.
        @inlinable
        public init?(points: Cardinal, outer: Geometry.Radius, inner: Geometry.Radius) {
            self.init(points: points, outer: outer, inner: inner, at: .zero)
        }
    }

    extension Geometry.Star where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// The distance from the center to the star's edge in the direction of an angle, measured
        /// counterclockwise from the positive x axis: `outer` toward a point, `inner` toward a notch, and on
        /// the straight edge between them in every other direction. It repeats with each point's share of
        /// the turn, and is the same on either side of a point.
        @inlinable
        public func radius(at angle: Radian<Scalar>) -> Geometry.Radius {
            let sector: Scalar = Scalar.pi / Scalar(points.rawValue)
            var within: Scalar = angle.underlying.truncatingRemainder(dividingBy: 2 * sector)
            if within < 0 { within += 2 * sector }
            if within > sector { within = 2 * sector - within }
            let notch = Radian<Scalar>(sector)
            let direction = Radian<Scalar>(within)
            let across: Scalar = inner.underlying * notch.cos.value - outer.underlying
            let down: Scalar = inner.underlying * notch.sin.value
            let reach: Scalar = outer.underlying * down / (direction.cos.value * down - direction.sin.value * across)
            return Geometry.Radius(reach)
        }

        /// The star's corners counterclockwise: a point, then the notch after it, and so on, starting with
        /// the point in the direction of the positive x axis; twice as many as it has points.
        @inlinable
        public var vertices: [Geometry.Point<2>] {
            let corners = 2 * points.rawValue
            return (0..<corners).map { index in
                let angle = Radian<Scalar>(Scalar.pi * Scalar(index) / Scalar(points.rawValue))
                let distance: Scalar = index.isMultiple(of: 2) ? outer.underlying : inner.underlying
                return Geometry.Point<2>([
                    center[0] + distance * angle.cos.value,
                    center[1] + distance * angle.sin.value,
                ])
            }
        }
    }

    extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// A star's border as one closed subpath of straight edges, counterclockwise from its first point.
        @inlinable
        public init(_ star: Geometry.Star) {
            let corners = star.vertices
            self.init(
                subpaths: [
                    Subpath(
                        startPoint: corners[0],
                        segments: zip(corners, corners.dropFirst() + corners.prefix(1)).map { start, end in
                            .line(Geometry.Line.Segment(start: start, end: end))
                        },
                        isClosed: true
                    )
                ]
            )
        }
    }
#endif
