#if Affine
    import Angle
    import Point
    import Scale

    public import Numeric

    extension Geometry.Path.Subpath where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// The subpath from its start to a length along it, as an open subpath.
        ///
        /// A closed subpath's closing line counts as its last segment. Lines and circular arcs are cut
        /// exactly; Bézier curves and elliptical arcs at the parameter where the length measured with
        /// `bezierSegments` chords reaches the rest. At no length the result is the start point alone;
        /// at the whole length or past it, the subpath itself.
        @inlinable
        public func prefix(length: Geometry.ArcLength, bezierSegments: Int = 100) -> Self {
            var rest: Scalar = length.underlying
            guard rest < self.length(bezierSegments: bezierSegments).underlying else { return self }
            var pieces: [Geometry.Path.Segment] = segments
            if isClosed, let end = endPoint, end != startPoint {
                pieces.append(.line(Geometry.Line.Segment(start: end, end: startPoint)))
            }
            var kept: [Geometry.Path.Segment] = []
            for piece in pieces {
                guard rest > 0 else { break }
                let whole: Scalar = piece.length(bezierSegments: bezierSegments)
                if rest >= whole {
                    kept.append(piece)
                    rest -= whole
                } else {
                    kept.append(piece.prefix(length: rest, of: whole, bezierSegments: bezierSegments))
                    rest = 0
                }
            }
            return Self(startPoint: startPoint, segments: kept, isClosed: false)
        }
    }
#endif
