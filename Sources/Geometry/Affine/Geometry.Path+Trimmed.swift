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

    extension Geometry.Path.Segment where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// The segment's length, its curves measured with a number of chords.
        @inlinable
        func length(bezierSegments: Int) -> Scalar {
            switch self {
            case .line(let line): Geometry.length(of: line).underlying
            case .bezier(let bezier): bezier.length(segments: bezierSegments).underlying
            case .arc(let arc): arc.length.underlying
            case .ellipticalArc(let arc): arc.length(segments: bezierSegments).underlying
            }
        }

        /// The segment from its start to a length along it shorter than its whole length.
        @inlinable
        func prefix(length: Scalar, of whole: Scalar, bezierSegments: Int) -> Self {
            let share: Scalar = whole > 0 ? length / whole : 0
            switch self {
            case .line(let line):
                return .line(Geometry.Line.Segment(start: line.start, end: Geometry.point(on: line, at: Scale(share))))
            case .arc(let arc):
                var cut = arc
                cut.endAngle = arc.startAngle + Scale(share) * arc.sweep
                return .arc(cut)
            case .bezier(let bezier):
                let parameter: Scalar = Self.parameter(reaching: length) { parameter in
                    bezier.split(at: Scale(parameter))?.left.length(segments: bezierSegments).underlying ?? 0
                }
                return .bezier(bezier.split(at: Scale(parameter))?.left ?? bezier)
            case .ellipticalArc(let arc):
                func cut(_ parameter: Scalar) -> Geometry.Ellipse.Arc {
                    var cut = arc
                    cut.endAngle = arc.startAngle + Scale(parameter) * arc.sweep
                    return cut
                }
                let parameter: Scalar = Self.parameter(reaching: length) { parameter in
                    cut(parameter).length(segments: bezierSegments).underlying
                }
                return .ellipticalArc(cut(parameter))
            }
        }

        /// The parameter in 0...1 at which a length that grows with it reaches a target, by bisection.
        @inlinable
        static func parameter(reaching target: Scalar, _ length: (Scalar) -> Scalar) -> Scalar {
            var low: Scalar = 0
            var high: Scalar = 1
            let precision: Scalar = Scalar.ulpOfOne * 64
            while high - low > precision {
                let middle: Scalar = (low + high) / 2
                if length(middle) < target { low = middle } else { high = middle }
            }
            return (low + high) / 2
        }
    }
#endif
