#if Affine
    import Direction
    @testable import Geometry
    import Geometry_Test_Support
    import Numeric
    import Testing

    private typealias Geo = Geometry<Double, Void>

    private func at(_ x: Double, _ y: Double) -> Geo.Point<2> { .init([x, y]) }

    private func near(_ a: Geo.Point<2>, _ b: Geo.Point<2>, within tolerance: Double = 1e-9) -> Bool {
        abs(a[0] - b[0]) <= tolerance && abs(a[1] - b[1]) <= tolerance
    }

    private func arc(_ center: Geo.Point<2>, _ radius: Double, from start: Double, through sweep: Double) -> Geo.Arc {
        Geo.Arc(
            center: center,
            radius: .init(radius),
            startAngle: Radian(_unchecked: start),
            endAngle: Radian(_unchecked: start + sweep)
        )
    }

    private func area(_ path: Geo.Path) throws -> Double {
        let flat = try path.flattened(tolerance: 1e-5)
        return flat.subpaths.reduce(0) { total, subpath in
            var points = [subpath.startPoint]
            points.append(contentsOf: subpath.segments.compactMap(\.endPoint))
            points.append(subpath.startPoint)
            return total + zip(points, points.dropFirst()).reduce(0) { $0 + ($1.0[0] * $1.1[1] - $1.1[0] * $1.0[1]) / 2 }
        }
    }

    @Suite
    struct `Geometry.Path arc and sector Tests` {
        static let sweeps = [0.4, Double.pi / 2, -2.2, 2 * Double.pi, 3 * Double.pi]

        @Test(arguments: sweeps)
        func `An open arc runs from the arc's start point to its end point`(sweep: Double) throws {
            let arc = arc(at(2, -1), 3, from: 0.7, through: sweep)
            let path = Geo.Path(arc)
            let subpath = path.subpaths[0]
            #expect(path.subpaths.count == 1 && !subpath.isClosed)
            #expect(near(subpath.startPoint, at(2 + 3 * Double.cos(0.7), -1 + 3 * Double.sin(0.7))))
            let end = try #require(subpath.endPoint)
            #expect(near(end, at(2 + 3 * Double.cos(0.7 + sweep), -1 + 3 * Double.sin(0.7 + sweep))))
        }

        @Test(arguments: sweeps)
        func `An open arc is as long as its radius times its sweep, more than a turn included`(sweep: Double) {
            let path = Geo.Path(arc(at(0, 0), 2.5, from: -1, through: sweep))
            #expect(abs(path.subpaths[0].length().underlying - 2.5 * abs(sweep)) < 1e-9)
        }

        @Test(arguments: [0.4, Double.pi / 2, 2.2, -2.2, 5.0])
        func `A sector's area is half the radius squared times its sweep`(sweep: Double) throws {
            let path = Geo.Path(sector: arc(at(1, 4), 2, from: 0.3, through: sweep))
            #expect(path.subpaths.count == 1 && path.subpaths[0].isClosed)
            #expect(path.subpaths[0].startPoint == at(1, 4))
            #expect(abs(abs(try area(path)) - 2 * abs(sweep)) < 1e-3)
            #expect(try area(path) * sweep > 0)
        }

        @Test
        func `A sector of more than a turn is the whole disc, wound once`() throws {
            let path = Geo.Path(sector: arc(at(0, 0), 1, from: 0, through: 3 * Double.pi))
            #expect(abs(try area(path) - Double.pi) < 1e-3)
            #expect(path.winding(around: at(0.5, -0.2)) == 1)
            #expect(path.contains(at(-0.9, 0), rule: .evenodd))
        }
    }
#endif
