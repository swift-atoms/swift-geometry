#if Affine
    public import Angle
    public import Cardinal
    import Point
    public import Scale
    import Trigonometry

    public import Numeric

    extension Geometry {

        /// A closed curve given by its distance from a centre in every direction: the radial function r(θ),
        /// with θ measured counterclockwise from the positive x axis. The function is a shape about no centre
        /// in particular; a centre is given when the curve is sampled. A negative radius lies on the far side
        /// of the centre, as in polar coordinates.
        public struct Radial {

            /// The radius in each direction.
            @usableFromInline
            let reach: @Sendable (Radian<Scalar>) -> Radius

            /// The radial curve whose radius in the direction of an angle is `radius` of that angle.
            @inlinable
            public init(_ radius: @escaping @Sendable (Radian<Scalar>) -> Radius) {
                self.reach = radius
            }
        }
    }

    extension Geometry.Radial: Sendable {}

    extension Geometry.Radial {

        /// The radius in the direction of an angle, measured counterclockwise from the positive x axis.
        @inlinable
        public func radius(at angle: Radian<Scalar>) -> Geometry.Radius {
            reach(angle)
        }

        /// The circle of a radius: the same radius in every direction.
        @inlinable
        public init(radius: Geometry.Radius) where Scalar: Sendable {
            self.init { _ in radius }
        }
    }

    extension Geometry.Radial where Scalar: FloatingPoint {

        /// The curve a share `t` of the way from this one to `other`, direction by direction: its radius
        /// at θ is r(θ) + t × (r′(θ) − r(θ)). At 0 it is this curve, at 1 it is `other`, and `t` outside
        /// the unit interval extrapolates.
        @inlinable
        public func mixed(to other: Self, at t: Scale<1, Scalar>) -> Self where Scalar: Sendable {
            let share: Scalar = t.value
            return Self { angle in
                let from: Scalar = self.reach(angle).underlying
                let to: Scalar = other.reach(angle).underlying
                return Geometry.Radius(from + (to - from) * share)
            }
        }
    }

    extension Geometry.Radial where Scalar: FloatingPoint & Sendable {

        /// The curve turned counterclockwise by `angle` about its centre: its radius at θ is r(θ − angle),
        /// so a turn by a whole turn is the curve itself, up to the rounding of the angle.
        @inlinable
        public func rotated(by angle: Radian<Scalar>) -> Self {
            Self { direction in self.reach(Radian(_unchecked: direction.underlying - angle.underlying)) }
        }

        /// The curve scaled about its centre by `factor`: its radius at θ is `factor` × r(θ). A negative
        /// factor puts every point on the far side of the centre.
        @inlinable
        public func scaled(by factor: Scale<1, Scalar>) -> Self {
            let factor: Scalar = factor.value
            return Self { direction in Geometry.Radius(self.reach(direction).underlying * factor) }
        }
    }

    extension Geometry.Radial where Scalar: BinaryFloatingPoint & Numeric.Transcendental & Sendable {

        /// The star's edge as a radial curve, `Geometry.Star.radius(at:)`, about whatever centre it is
        /// sampled at; the star's own centre is not kept.
        @inlinable
        public init(_ star: Geometry.Star) {
            self.init { angle in star.radius(at: angle) }
        }
    }

    extension Geometry.Radial where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// The curve's points at `count` angles evenly spread over the turn about a centre, counterclockwise
        /// from the one in the direction of the positive x axis: the k-th lies at r(θ) from the centre in the
        /// direction θ = 2πk / `count`.
        @inlinable
        public func vertices(about center: Geometry.Point<2>, count: Cardinal) -> [Geometry.Point<2>] {
            let total = Int(bitPattern: count)
            return (0..<total).map { index in
                let angle = Radian<Scalar>(2 * Scalar.pi * Scalar(index) / Scalar(total))
                let distance: Scalar = reach(angle).underlying
                return Geometry.Point<2>([
                    center[0] + distance * angle.cos.value,
                    center[1] + distance * angle.sin.value,
                ])
            }
        }
    }

    extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// A radial curve about a centre as one closed subpath through its `samples` evenly spread points,
        /// `Geometry.Radial.vertices(about:count:)`, from the one in the direction of the positive x axis:
        /// joined by straight lines, as `polygon(vertices:)`, or by the smooth loop of `loop(through:)`.
        /// Nil for fewer than three samples.
        @inlinable
        public init?(
            _ radial: Geometry.Radial,
            about center: Geometry.Point<2>,
            samples: Cardinal,
            joined join: Geometry.Radial.Join = .straight
        ) {
            let corners = radial.vertices(about: center, count: samples)
            let path: Self? =
                switch join {
                case .straight: Self.polygon(vertices: corners)

                case .smooth: Self.loop(through: corners)
                }
            guard let path else { return nil }
            self = path
        }
    }
#endif
