#if Affine
    @testable import Geometry
    import Numeric
    import Testing

    private typealias Geo = Geometry<Double, Void>

    private func at(_ x: Double, _ y: Double) -> Geo.Point<2> { .init([x, y]) }

    /// The box as it was worked out before: from every Bézier `toBeziers()` makes.
    private func plain(_ path: Geo.Path) -> Geo.Rectangle? {
        let beziers = path.toBeziers().flatMap { $0 }
        guard let first = beziers.first?.boundingBoxConservative else { return nil }
        return beziers.dropFirst().reduce(first) { box, bezier in
            guard let next = bezier.boundingBoxConservative else { return box }
            return box.union(next)
        }
    }

    private func bits(_ box: Geo.Rectangle?) -> [UInt64]? {
        box.map { [$0.llx.underlying.bitPattern, $0.lly.underlying.bitPattern, $0.urx.underlying.bitPattern, $0.ury.underlying.bitPattern] }
    }

    private func line(_ a: Geo.Point<2>, _ b: Geo.Point<2>) -> Geo.Path.Segment { .line(.init(start: a, end: b)) }

    @Suite
    struct `Geometry.Path bounding box` {
        @Test
        func `A path's box, read in place, is bit for bit the box of its Béziers`() {
            let arc = Geo.Arc(center: at(1, 1), radius: 2, startAngle: .zero, endAngle: Radian(_unchecked: 2.5))
            let curve = Geo.Bezier.cubic(from: at(0, 0), control1: at(-3, 4), control2: at(5, -2), to: at(2, 2))
            let paths: [Geo.Path] = [
                .init(subpaths: []),
                .init(subpaths: [.init(startPoint: at(1, 1), segments: [])]),
                .init(subpaths: [.init(startPoint: at(0, 0), segments: [line(at(0, 0), at(3, -1)), line(at(3, -1), at(-2, 5))])]),
                .init(subpaths: [.init(startPoint: at(0, 0), segments: [line(at(0, 0), at(3, -1)), line(at(3, -1), at(-2, 5))], isClosed: true)]),
                .init(subpaths: [.init(startPoint: at(9, 9), segments: [line(at(0, 0), at(3, -1))], isClosed: true)]),
                .init(subpaths: [.init(startPoint: at(3, 1), segments: [.arc(arc)], isClosed: true)]),
                .init(subpaths: [.init(startPoint: at(0, 0), segments: [.bezier(curve), line(at(2, 2), at(7, 0))], isClosed: true),
                                 .init(startPoint: at(-0.0, 0), segments: [line(at(-0.0, 0), at(0, -0.0))])]),
                .init(subpaths: [.init(startPoint: at(0, 0), segments: [line(at(0, 0), at(.nan, 1)), line(at(.nan, 1), at(4, 4))], isClosed: true)]),
                .init(subpaths: [.init(startPoint: at(0, 0), segments: [.bezier(.init(controlPoints: [])), line(at(0, 0), at(1, 1))])]),
                .init(subpaths: [.init(startPoint: at(0, 0), segments: [line(at(0, 0), at(1, 1)), .bezier(.init(controlPoints: []))], isClosed: true)]),
                Geo.Path(Geo.Rectangle(llx: 0, lly: 0, urx: 10, ury: 6), radius: 2),
            ]
            for path in paths {
                #expect(bits(path.boundingBox) == bits(plain(path)))
            }
        }
    }
#endif
