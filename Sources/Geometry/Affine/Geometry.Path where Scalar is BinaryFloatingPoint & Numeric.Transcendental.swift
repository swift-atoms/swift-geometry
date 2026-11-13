#if Affine
    public import Angle
    import Point
    import Scale

    public import Numeric

    extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// Each subpath from its start to a share of its own length: the start point alone at 0, the
        /// whole subpath at 1. Drawing a path on over time is this path at a share that grows.
        @inlinable
        public func trimmed(to share: Scale<1, Scalar>) -> Self {
            let fraction: Scalar = Swift.min(Swift.max(share.value, 0), 1)
            return Self(
                subpaths: subpaths.map { subpath in
                    let total: Scalar = subpath.length().underlying
                    return subpath.prefix(length: Geometry.ArcLength(total * fraction))
                }
            )
        }
    }

    extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// The arc as an open path: one subpath from the arc's start point holding the arc alone, so it is
        /// stroked, not filled. Its sweep is kept as given, so an arc of more than a turn runs round again.
        @inlinable
        public init(_ arc: Geometry.Arc) {
            self.init(subpaths: [Subpath(startPoint: arc.startPoint, segments: [.arc(arc)], isClosed: false)])
        }

        /// The pie slice of an arc: one closed subpath from the arc's centre straight out to its start
        /// point, along the arc and straight back. The sweep is held to one turn either way, so the slice
        /// never winds twice and a sweep of a turn or more is the whole disc.
        @inlinable
        public init(sector arc: Geometry.Arc) {
            let turn: Scalar = 2 * Scalar.pi
            let sweep: Scalar = Swift.min(Swift.max(arc.sweep.underlying, -turn), turn)
            var held = arc
            held.endAngle = Radian(_unchecked: arc.startAngle.underlying + sweep)
            self.init(subpaths: [
                Subpath(
                    startPoint: held.center,
                    segments: [.line(.init(start: held.center, end: held.startPoint)), .arc(held)],
                    isClosed: true
                )
            ])
        }
    }
#endif
