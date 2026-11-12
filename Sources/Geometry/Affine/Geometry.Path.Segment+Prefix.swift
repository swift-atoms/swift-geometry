#if Affine
    import Angle
    import Point
    import Scale

    public import Numeric

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
