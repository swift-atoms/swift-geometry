#if Affine

    extension Geometry {

        /// The region between two circles about one center: every point at least `inner` and at most `outer`
        /// from the center. An inner radius of zero is the disc of the outer one.
        public struct Annulus {

            /// The middle of both circles.
            public var center: Point<2>

            /// The radius of the hole, not negative.
            public let inner: Radius

            /// The radius of the outer edge, not less than `inner`.
            public let outer: Radius

            /// The region between `inner` and `outer` about a center; nil for an inner radius below zero or above
            /// the outer one.
            @inlinable
            public init?(center: Point<2>, inner: Radius, outer: Radius) where Scalar: Comparable & AdditiveArithmetic {
                guard inner.underlying >= .zero, inner.underlying <= outer.underlying else { return nil }
                self.center = center
                self.inner = inner
                self.outer = outer
            }
        }
    }

    extension Geometry.Annulus: Sendable where Scalar: Sendable {}
    extension Geometry.Annulus: Equatable where Scalar: Equatable {}
    extension Geometry.Annulus: Hashable where Scalar: Hashable {}

    #if !hasFeature(Embedded)
        extension Geometry.Annulus: Codable where Scalar: Codable & Comparable & AdditiveArithmetic {
            private enum CodingKeys: String, CodingKey {
                case center, inner, outer
            }

            /// Decodes an annulus, failing for an inner radius below zero or above the outer one.
            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                guard
                    let annulus = Self(
                        center: try container.decode(Geometry.Point<2>.self, forKey: .center),
                        inner: try container.decode(Geometry.Radius.self, forKey: .inner),
                        outer: try container.decode(Geometry.Radius.self, forKey: .outer)
                    )
                else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .inner,
                        in: container,
                        debugDescription: "An annulus's inner radius lies from zero to its outer radius"
                    )
                }
                self = annulus
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(center, forKey: .center)
                try container.encode(inner, forKey: .inner)
                try container.encode(outer, forKey: .outer)
            }
        }
    #endif

    extension Geometry.Annulus where Scalar: FloatingPoint {

        /// The band about a middle circle: `radius` from the center to the middle of the band, `width` across
        /// it, so the inner radius is `radius − width / 2` and the outer `radius + width / 2`; nil for a width
        /// below zero or one wider than twice the radius.
        @inlinable
        public init?(center: Geometry.Point<2>, radius: Geometry.Radius, width: Geometry.Length) {
            guard width.underlying >= 0 else { return nil }
            let half: Scalar = width.underlying / 2
            self.init(
                center: center,
                inner: Geometry.Radius(radius.underlying - half),
                outer: Geometry.Radius(radius.underlying + half)
            )
        }

        /// The distance across the band: `outer − inner`.
        @inlinable
        public var width: Geometry.Length {
            Geometry.Length(outer.underlying - inner.underlying)
        }

        /// The radius of the circle down the middle of the band: halfway between `inner` and `outer`.
        @inlinable
        public var radius: Geometry.Radius {
            Geometry.Radius((inner.underlying + outer.underlying) / 2)
        }

        /// The circle of the outer edge.
        @inlinable
        public var outerCircle: Geometry.Circle {
            Geometry.Circle(center: center, radius: outer)
        }

        /// The circle of the hole.
        @inlinable
        public var innerCircle: Geometry.Circle {
            Geometry.Circle(center: center, radius: inner)
        }

        /// The area between the two circles: π(outer² − inner²).
        @inlinable
        public var area: Geometry.Area {
            let (o, i): (Scalar, Scalar) = (outer.underlying, inner.underlying)
            return Geometry.Area(Scalar.pi * (o * o - i * i))
        }

        /// Whether `point` lies in the band, its two edges included.
        @inlinable
        public func contains(_ point: Geometry.Point<2>) -> Bool {
            let distance: Scalar = center.distance(to: point).underlying
            return distance >= inner.underlying && distance <= outer.underlying
        }
    }
#endif
