#if Affine
    import Direction
    @testable import Geometry
    import Geometry_Test_Support
    import Numeric
    import Scale
    import Testing

    private typealias Geo = Geometry<Double, Void>

    private func at(_ x: Double, _ y: Double) -> Geo.Point<2> { .init([x, y]) }

    private func run(_ corners: [(Double, Double)], closed: Bool = false) -> Geo.Path {
        var segments: [Geo.Path.Segment] = []
        corners.indices.dropFirst().forEach { index in
            segments.append(.line(.init(start: at(corners[index - 1].0, corners[index - 1].1), end: at(corners[index].0, corners[index].1))))
        }
        return .init(subpaths: [.init(startPoint: at(corners[0].0, corners[0].1), segments: segments, isClosed: closed)])
    }

    private func pen(_ width: Double, _ join: Geo.Path.Stroke.Join, _ cap: Geo.Path.Stroke.Cap) -> Geo.Path.Stroke {
        .init(width: .init(width), join: join, cap: cap)
    }

    /// The distance from a point to the nearest point of the straight run through the corners.
    private func distance(_ x: Double, _ y: Double, to corners: [(Double, Double)], closed: Bool = false) -> Double {
        var best = Double.infinity
        let ends = closed ? corners + [corners[0]] : corners
        ends.indices.dropFirst().forEach { index in
            let a = ends[index - 1]
            let b = ends[index]
            let chord = (x: b.0 - a.0, y: b.1 - a.1)
            let squared = chord.x * chord.x + chord.y * chord.y
            let along = squared > 0 ? min(max(((x - a.0) * chord.x + (y - a.1) * chord.y) / squared, 0), 1) : 0
            let away = (x: x - a.0 - along * chord.x, y: y - a.1 - along * chord.y)
            best = min(best, (away.x * away.x + away.y * away.y).squareRoot())
        }
        return best
    }

    /// Grid points over a box, as (x, y) pairs.
    private func grid(from low: Double, to high: Double, step: Double) -> [(Double, Double)] {
        var points: [(Double, Double)] = []
        var x = low
        while x <= high {
            var y = low
            while y <= high {
                points.append((x, y))
                y += step
            }
            x += step
        }
        return points
    }

    private let zigzag: [(Double, Double)] = [(0, 0), (10, 0), (10, 6), (2, 9), (9, 12), (9, 3), (-3, 14)]

    enum `Geometry.Path.Stroke Tests` {}

    extension `Geometry.Path.Stroke Tests` {
        @Suite
        struct `A stroke outline fills, under the nonzero rule, to the stroked region` {
            @Test(arguments: [false, true])
            func `With round joins and caps it is every point within half the width of the path`(closed: Bool) throws {
                let outline = try run(zigzag, closed: closed).stroked(pen(3, .round, .round), tolerance: 0.01)
                var inside = 0
                grid(from: -6, to: 17, step: 0.37).forEach { point in
                    let away = distance(point.0, point.1, to: zigzag, closed: closed)
                    guard abs(away - 1.5) > 1e-6 else { return }
                    #expect(outline.contains(at(point.0, point.1), rule: .nonzero) == (away < 1.5), "at \(point)")
                    if away < 1.5 { inside += 1 }
                }
                #expect(inside > 400)
            }

            @Test(arguments: [false, true])
            func `Every piece runs counterclockwise, whichever way the path runs`(closed: Bool) throws {
                let forward = try run(zigzag, closed: closed).stroked(pen(3, .miter(limit: 4), .square), tolerance: 0.01)
                let backward = try run(zigzag.reversed(), closed: closed).stroked(pen(3, .bevel, .round), tolerance: 0.01)
                grid(from: -6, to: 17, step: 0.61).forEach { point in
                    #expect(forward.winding(around: at(point.0, point.1)) >= 0)
                    #expect(backward.winding(around: at(point.0, point.1)) >= 0)
                }
                #expect(forward.winding(around: at(5, 0.2)) >= 1)
                #expect(backward.winding(around: at(5, 0.2)) >= 1)
                #expect(forward.subpaths.allSatisfy { $0.isClosed })
                #expect(backward.subpaths.allSatisfy { $0.isClosed })
            }

            @Test
            func `A straight line with butt caps is its rectangle`() throws {
                let outline = try run([(0, 0), (10, 0)]).stroked(pen(2, .bevel, .butt), tolerance: 0.01)
                #expect(outline.subpaths.count == 1)
                [(0.01, 0), (9.99, 0), (5, 0.99), (5, -0.99), (0.01, 0.99)].forEach { point in
                    #expect(outline.contains(at(point.0, point.1), rule: .nonzero), "at \(point)")
                }
                [(-0.01, 0), (10.01, 0), (5, 1.01), (5, -1.01)].forEach { point in
                    #expect(!outline.contains(at(point.0, point.1), rule: .nonzero), "at \(point)")
                }
            }

            @Test
            func `Square caps extend each end by half the width`() throws {
                let outline = try run([(0, 0), (10, 0)]).stroked(pen(2, .bevel, .square), tolerance: 0.01)
                [(-0.99, 0.99), (-0.99, -0.99), (10.99, 0.99), (10.99, -0.99), (5, 0)].forEach { point in
                    #expect(outline.contains(at(point.0, point.1), rule: .nonzero), "at \(point)")
                }
                [(-1.01, 0), (11.01, 0), (-0.5, 1.01), (10.5, -1.01)].forEach { point in
                    #expect(!outline.contains(at(point.0, point.1), rule: .nonzero), "at \(point)")
                }
            }

            @Test
            func `Round caps are half discs beyond each end`() throws {
                let outline = try run([(0, 0), (10, 0)]).stroked(pen(2, .bevel, .round), tolerance: 0.01)
                [(-0.99, 0), (10.99, 0), (-0.7, 0.7), (10.7, -0.7)].forEach { point in
                    #expect(outline.contains(at(point.0, point.1), rule: .nonzero), "at \(point)")
                }
                [(-1.01, 0), (11.01, 0), (-0.75, 0.75), (10.75, -0.75)].forEach { point in
                    #expect(!outline.contains(at(point.0, point.1), rule: .nonzero), "at \(point)")
                }
            }

            @Test(arguments: [1.0, -1.0])
            func `The three joins fill the outer corner differently`(side: Double) throws {
                // A right angle at (10, 0) turning left (side 1) or right (side −1); the outer corner is (11, −side).
                let corner = run([(0, 0), (10, 0), (10, 10 * side)])
                let miter = try corner.stroked(pen(2, .miter(limit: 4), .butt), tolerance: 0.01)
                let bevel = try corner.stroked(pen(2, .bevel, .butt), tolerance: 0.01)
                let round = try corner.stroked(pen(2, .round, .butt), tolerance: 0.01)
                #expect(miter.contains(at(10.99, -0.99 * side), rule: .nonzero))
                #expect(!miter.contains(at(11.01, -0.5 * side), rule: .nonzero))
                #expect(!miter.contains(at(10.5, -1.01 * side), rule: .nonzero))
                #expect(bevel.contains(at(10.45, -0.45 * side), rule: .nonzero))
                #expect(!bevel.contains(at(10.55, -0.55 * side), rule: .nonzero))
                #expect(round.contains(at(10.7, -0.7 * side), rule: .nonzero))
                #expect(!round.contains(at(10.75, -0.75 * side), rule: .nonzero))
                [miter, bevel, round].forEach { outline in
                    #expect(outline.contains(at(9.5, 0.5 * side), rule: .nonzero))
                    #expect(!outline.contains(at(8.9, 1.1 * side), rule: .nonzero))
                }
            }

            @Test
            func `A miter longer than the limit times the width becomes a bevel`() throws {
                // At a right angle the miter is √2 times the width.
                let corner = run([(0, 0), (10, 0), (10, 10)])
                let under = try corner.stroked(pen(2, .miter(limit: 1.42), .butt), tolerance: 0.01)
                let over = try corner.stroked(pen(2, .miter(limit: 1.41), .butt), tolerance: 0.01)
                #expect(under.contains(at(10.9, -0.9), rule: .nonzero))
                #expect(!over.contains(at(10.9, -0.9), rule: .nonzero))
                #expect(over.contains(at(10.45, -0.45), rule: .nonzero))
                #expect(try over == corner.stroked(pen(2, .bevel, .butt), tolerance: 0.01))
            }

            @Test
            func `A path that doubles back is rounded by a round join and cut square by the others`() throws {
                let spike = run([(0, 0), (10, 0), (0, 0.0)])
                let round = try spike.stroked(pen(2, .round, .butt), tolerance: 0.01)
                let miter = try spike.stroked(pen(2, .miter(limit: 100), .butt), tolerance: 0.01)
                #expect(round.contains(at(10.9, 0), rule: .nonzero))
                #expect(!round.contains(at(11.1, 0), rule: .nonzero))
                #expect(!miter.contains(at(10.1, 0), rule: .nonzero))
                #expect(miter.contains(at(9.9, 0.9), rule: .nonzero))
            }

            @Test
            func `A closed subpath is joined at its start and has no caps`() throws {
                let box = run([(0, 0), (10, 0), (10, 10), (0, 10)], closed: true)
                let outline = try box.stroked(pen(2, .miter(limit: 4), .square), tolerance: 0.01)
                [(-0.99, -0.99), (10.99, -0.99), (10.99, 10.99), (-0.99, 10.99), (-0.9, 5), (5, 10.9)].forEach { point in
                    #expect(outline.contains(at(point.0, point.1), rule: .nonzero), "at \(point)")
                }
                [(5, 5), (1.1, 1.1), (-1.01, 5), (11.5, 11.5)].forEach { point in
                    #expect(!outline.contains(at(point.0, point.1), rule: .nonzero), "at \(point)")
                }
                let explicit = run([(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)], closed: true)
                #expect(try explicit.stroked(pen(2, .miter(limit: 4), .square), tolerance: 0.01) == outline)
            }

            @Test
            func `An open path that returns to its start keeps its caps and has no join there`() throws {
                let open = run([(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)])
                let outline = try open.stroked(pen(2, .miter(limit: 4), .butt), tolerance: 0.01)
                #expect(!outline.contains(at(-0.9, -0.9), rule: .nonzero))
                #expect(outline.contains(at(10.9, -0.9), rule: .nonzero))
            }

            @Test
            func `A curve is stroked along its flattening, inside the tolerance of the true stroke`() throws {
                let arc = Geo.Arc(center: at(0, 0), radius: 10, startAngle: .zero, endAngle: .pi.two)
                let ring = Geo.Path(subpaths: [.init(startPoint: at(10, 0), segments: [.arc(arc)], isClosed: true)])
                let outline = try ring.stroked(pen(2, .bevel, .butt), tolerance: 0.01)
                [0.0, 0.05, 0.4, 1.3, 2.2, 3.1, 4.7, 6.2].forEach { direction in
                    let unit = (x: Double.cos(direction), y: Double.sin(direction))
                    #expect(outline.contains(at(10.98 * unit.x, 10.98 * unit.y), rule: .nonzero))
                    #expect(!outline.contains(at(11.02 * unit.x, 11.02 * unit.y), rule: .nonzero))
                    #expect(outline.contains(at(9.02 * unit.x, 9.02 * unit.y), rule: .nonzero))
                    #expect(!outline.contains(at(8.98 * unit.x, 8.98 * unit.y), rule: .nonzero))
                }
            }

            @Test
            func `Vertices that flattening put inside a curve take round joins whatever join is asked`() throws {
                // A tight circle under a wide pen: flattening makes 23 chords, so a bevel at each vertex would cut 0.09 deep.
                let arc = Geo.Arc(center: at(0, 0), radius: 1, startAngle: .zero, endAngle: .pi.two)
                let ring = Geo.Path(subpaths: [.init(startPoint: at(1, 0), segments: [.arc(arc)], isClosed: true)])
                let flat = try ring.flattened(tolerance: 0.01)
                #expect(flat.segmentCount == 23)
                let outline = try ring.stroked(pen(20, .bevel, .butt), tolerance: 0.01)
                [3.0, 7, 11, 16, 20].forEach { vertex in
                    let direction = 2 * Double.pi * vertex / 23
                    let unit = (x: Double.cos(direction), y: Double.sin(direction))
                    #expect(outline.contains(at(10.97 * unit.x, 10.97 * unit.y), rule: .nonzero))
                    #expect(!outline.contains(at(11.01 * unit.x, 11.01 * unit.y), rule: .nonzero))
                }
                // The start of the closed subpath is a corner of the path itself, so it takes the bevel.
                #expect(!outline.contains(at(10.97, 0), rule: .nonzero))
                #expect(try ring.stroked(pen(20, .round, .butt), tolerance: 0.01).contains(at(10.97, 0), rule: .nonzero))
            }

            @Test
            func `A subpath with no length is a dot shaped by the cap`() throws {
                let dot = run([(3, 4), (3, 4)])
                let round = try dot.stroked(pen(2, .bevel, .round), tolerance: 0.01)
                let square = try dot.stroked(pen(2, .bevel, .square), tolerance: 0.01)
                #expect(round.contains(at(3.99, 4), rule: .nonzero))
                #expect(round.contains(at(3, 3.01), rule: .nonzero))
                #expect(!round.contains(at(3.75, 4.75), rule: .nonzero))
                #expect(round.winding(around: at(3, 4)) == 1)
                #expect(square.contains(at(3.99, 4.99), rule: .nonzero))
                #expect(square.contains(at(2.01, 3.01), rule: .nonzero))
                #expect(!square.contains(at(4.01, 4), rule: .nonzero))
                #expect(square.winding(around: at(3, 4)) == 1)
                #expect(try dot.stroked(pen(2, .bevel, .butt), tolerance: 0.01).isEmpty)
                let bare = Geo.Path(subpaths: [.init(startPoint: at(3, 4), segments: [], isClosed: false)])
                #expect(try bare.stroked(pen(2, .round, .round), tolerance: 0.01).isEmpty)
            }

            @Test
            func `Subpaths are stroked one after another, in order`() throws {
                let first = run([(0, 0), (10, 0), (10, 10)])
                let second = run([(20, 0), (30, 0), (20, 10)], closed: true)
                let both = Geo.Path(subpaths: first.subpaths + second.subpaths)
                let stroke = pen(2, .round, .square)
                #expect(try both.stroked(stroke, tolerance: 0.01).subpaths == first.stroked(stroke, tolerance: 0.01).subpaths + second.stroked(stroke, tolerance: 0.01).subpaths)
            }

            @Test
            func `A zero width strokes nothing`() throws {
                #expect(try run(zigzag).stroked(pen(0, .round, .round), tolerance: 0.01).isEmpty)
            }

            @Test
            func `Widths, limits and tolerances outside their range are refused`() {
                let path = run(zigzag)
                [-1, Double.nan, Double.infinity].forEach { width in
                    #expect(throws: Geo.Path.Error.width) { try path.stroked(pen(width, .round, .round), tolerance: 0.01) }
                }
                [0.99, 0, -3, Double.nan, Double.infinity].forEach { limit in
                    #expect(throws: Geo.Path.Error.limit) { try path.stroked(pen(2, .miter(limit: Scale(limit)), .round), tolerance: 0.01) }
                }
                [0, -1, Double.nan, Double.infinity].forEach { tolerance in
                    #expect(throws: Geo.Path.Error.tolerance) { try path.stroked(pen(2, .round, .round), tolerance: .init(tolerance)) }
                }
                #expect(throws: Never.self) { try path.stroked(pen(2, .miter(limit: 1), .round), tolerance: 0.01) }
            }
        }
    }
#endif
