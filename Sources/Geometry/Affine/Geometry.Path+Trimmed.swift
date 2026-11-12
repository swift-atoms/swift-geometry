#if Affine
    import Angle
    import Point
    import Scale

    public import Numeric

    extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// Each subpath from its start to a share of its own length: the start point alone at 0, the
        /// whole subpath at 1. Drawing a path on over time is this path at a share that grows.
        @inlinable
        public func trimmed(to share: Scale<1, Scalar>, bezierSegments: Int = 100) -> Self {
            let fraction: Scalar = Swift.min(Swift.max(share.value, 0), 1)
            return Self(
                subpaths: subpaths.map { subpath in
                    let total: Scalar = subpath.length(bezierSegments: bezierSegments).underlying
                    return subpath.prefix(length: Geometry.ArcLength(total * fraction), bezierSegments: bezierSegments)
                }
            )
        }
    }
#endif
