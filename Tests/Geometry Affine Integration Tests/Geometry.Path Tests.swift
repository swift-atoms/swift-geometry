#if Affine
    import Direction
    @testable import Geometry
    import Geometry_Test_Support
    import Matrix
    import Numeric
    import Scale
    import Testing
    import Vector

    private enum Font {}
    private enum Page {}

    private typealias Geo = Geometry<Double, Void>
    private typealias Map = Matrix<2, 3, Double>

    private func at(_ x: Double, _ y: Double) -> Geo.Point<2> { .init([x, y]) }

    private func near(_ a: Geo.Point<2>, _ b: Geo.Point<2>, within tolerance: Double = 1e-9) -> Bool {
        abs(a[0] - b[0]) <= tolerance && abs(a[1] - b[1]) <= tolerance
    }

    private func line(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Geo.Path.Segment {
        .line(.init(start: at(x0, y0), end: at(x1, y1)))
    }

    private func polygon(_ corners: [(Double, Double)]) -> Geo.Path.Subpath {
        var segments: [Geo.Path.Segment] = []
        corners.indices.dropFirst().forEach { index in
            segments.append(line(corners[index - 1].0, corners[index - 1].1, corners[index].0, corners[index].1))
        }
        return .init(startPoint: at(corners[0].0, corners[0].1), segments: segments, isClosed: true)
    }

    private func square(_ low: Double, _ high: Double, clockwise: Bool = false) -> Geo.Path.Subpath {
        let corners = [(low, low), (high, low), (high, high), (low, high)]
        return polygon(clockwise ? corners.reversed() : corners)
    }

    private func circle(radius: Double, turns: Double = 1) -> Geo.Path.Subpath {
        let arc = Geo.Arc(center: at(0, 0), radius: .init(radius), startAngle: .zero, endAngle: Radian(_unchecked: 2 * Double.pi * turns))
        return .init(startPoint: at(radius, 0), segments: [.arc(arc)], isClosed: true)
    }

    private let maps: [Map] = [
        Map(rows: [[1, 0, 0], [0, 1, 0]]),
        Map(rows: [[0, -1, 3], [1, 0, -2]]),
        Map(rows: [[3, 0, 1], [0, 0.5, 2]]),
        Map(rows: [[1, 2, -4], [0, 1, 7]]),
        Map(rows: [[1, 0, 0], [0, -1, 5]]),
        Map(rows: [[2, -1, 0.5], [0.75, 3, -6]]),
        Map(rows: [[-0.3, 1.7, 2], [1.1, 0.4, 0]]),
    ]

    private let parameters: [Double] = [0, 0.125, 0.25, 0.5, 0.75, 1]

    enum `Geometry.Path Tests` {}

    // MARK: - Shapes as paths

    extension `Geometry.Path Tests` {
        @Suite
        struct `A rectangle and a circle are paths of one closed subpath` {
            @Test
            func `A rectangle is its four sides from its lower-left corner, counterclockwise`() {
                let path = Geo.Path(Geo.Rectangle(llx: 1, lly: 2, urx: 5, ury: 4))
                #expect(path.subpaths.count == 1)
                #expect(path.subpaths[0].isClosed)
                #expect(path.subpaths[0].startPoint == at(1, 2))
                #expect(path.subpaths[0].segments == [line(1, 2, 5, 2), line(5, 2, 5, 4), line(5, 4, 1, 4), line(1, 4, 1, 2)])
                #expect(path.winding(around: at(3, 3)) == 1)
                #expect(path == Geo.Path(Geo.Rectangle(llx: 1, lly: 2, urx: 5, ury: 4), radius: 0))
                #expect(path == Geo.Path(Geo.Rectangle(llx: 1, lly: 2, urx: 5, ury: 4), radius: -3))
                #expect(path == Geo.Path(Geo.Rectangle(llx: 1, lly: 2, urx: 5, ury: 4), radius: .init(Double.nan)))
            }

            @Test
            func `A radius rounds each corner with a quarter circle that touches both sides`() throws {
                let rectangle = Geo.Rectangle(llx: 0, lly: 0, urx: 10, ury: 6)
                let path = Geo.Path(rectangle, radius: 2)
                let subpath = try #require(path.subpaths.first)
                #expect(path.subpaths.count == 1 && subpath.isClosed && subpath.segments.count == 8)
                #expect(subpath.startPoint == at(2, 0))
                var pen = subpath.startPoint
                for segment in subpath.segments {
                    #expect(near(try #require(segment.startPoint), pen))
                    pen = try #require(segment.endPoint)
                }
                #expect(near(pen, subpath.startPoint))
                let centres = [at(8, 2), at(8, 4), at(2, 4), at(2, 2)]
                let arcs = subpath.segments.compactMap { segment -> Geo.Arc? in
                    if case .arc(let arc) = segment { return arc }
                    return nil
                }
                #expect(arcs.map(\.center) == centres)
                #expect(arcs.allSatisfy { $0.radius == 2 && $0.isCounterClockwise && abs($0.sweep.underlying - Double.pi / 2) < 1e-12 })
                let box = try #require(path.boundingBox)
                #expect(near(at(box.llx.underlying, box.lly.underlying), at(0, 0)) && near(at(box.urx.underlying, box.ury.underlying), at(10, 6)))
                #expect(path.contains(at(5, 3), rule: .nonzero))
                #expect(path.contains(at(0.1, 3), rule: .nonzero) && path.contains(at(5, 5.9), rule: .nonzero))
                #expect(path.contains(at(0.7, 0.7), rule: .nonzero))
                #expect(!path.contains(at(0.5, 0.5), rule: .nonzero))
                #expect(!path.contains(at(9.5, 5.5), rule: .nonzero) && !path.contains(at(9.5, 0.5), rule: .nonzero) && !path.contains(at(0.5, 5.5), rule: .nonzero))
                #expect(Geo.Path(rectangle).contains(at(0.5, 0.5), rule: .nonzero))
            }

            @Test
            func `A radius is held to half the shorter side`() throws {
                let pill = Geo.Path(Geo.Rectangle(llx: 0, lly: 0, urx: 10, ury: 4), radius: 100)
                #expect(pill == Geo.Path(Geo.Rectangle(llx: 0, lly: 0, urx: 10, ury: 4), radius: 2))
                let flat = try pill.flattened(tolerance: 0.001)
                let reach = flat.subpaths[0].segments.compactMap(\.endPoint).map { point -> Double in
                    let x = Swift.min(Swift.max(point[0], 2), 8)
                    return ((point[0] - x) * (point[0] - x) + (point[1] - 2) * (point[1] - 2)).squareRoot()
                }
                #expect(reach.allSatisfy { abs($0 - 2) < 0.002 })
            }

            @Test
            func `A circle is its full arc from its rightmost point`() throws {
                let path = Geo.Path(Geo.Circle(center: at(3, -1), radius: 2))
                #expect(path.subpaths.count == 1)
                #expect(path.subpaths[0].isClosed)
                #expect(path.subpaths[0].startPoint == at(5, -1))
                #expect(path.subpaths[0].segments == [.arc(.fullCircle(center: at(3, -1), radius: 2))])
                #expect(path.contains(at(3, -1), rule: .nonzero) && path.contains(at(4.4, -2.4), rule: .nonzero))
                #expect(!path.contains(at(4.5, -2.5), rule: .nonzero))
                let flat = try path.flattened(tolerance: 0.001)
                #expect(flat.subpaths[0].segments.compactMap(\.endPoint).allSatisfy { point in
                    abs(((point[0] - 3) * (point[0] - 3) + (point[1] + 1) * (point[1] + 1)).squareRoot() - 2) < 1e-9
                })
            }
        }
    }

    // MARK: - Transforming

    extension `Geometry.Path Tests` {
        @Suite
        struct `An affine map moves a path point by point` {
            @Test
            func `A point is the matrix applied to it, tagged with the target space`() {
                let map = Map(rows: [[2, -1, 0.5], [0.75, 3, -6]])
                let source = Geometry<Double, Font>.Point<2>([4, 8])
                let image: Geometry<Double, Page>.Point<2> = source.transformed(by: map, to: Page.self)
                #expect(image == Geometry<Double, Page>.Point<2>([0.5, 21]))
                #expect(image.coordinates[0] == map.applied(to: Vector([4, 8]))[0])
                #expect(source.transformed(by: map) == Geometry<Double, Font>.Point<2>([0.5, 21]))
            }

            @Test(arguments: maps)
            func `A Bézier curve maps control point by control point and stays the same curve`(map: Matrix<2, 3, Double>) throws {
                let curve = Geo.Bezier.cubic(from: at(0, 0), control1: at(1, 3), control2: at(4, -2), to: at(5, 1))
                let image = curve.transformed(by: map)
                #expect(image.controlPoints == curve.controlPoints.map { $0.transformed(by: map) })
                try parameters.forEach { parameter in
                    let moved = try #require(curve.point(at: Scale(parameter))).transformed(by: map)
                    #expect(near(try #require(image.point(at: Scale(parameter))), moved))
                }
            }

            @Test(arguments: maps)
            func `An elliptical arc maps to the elliptical arc through the moved points`(map: Matrix<2, 3, Double>) {
                let arcs = [
                    Geo.Ellipse.Arc(center: at(1, -2), semiMajor: 3, semiMinor: 1.5, rotation: Radian(_unchecked: 0.4), startAngle: Radian(_unchecked: 0.3), endAngle: Radian(_unchecked: 2.9)),
                    Geo.Ellipse.Arc(center: at(0, 0), semiMajor: 1, semiMinor: 2, rotation: .zero, startAngle: Radian(_unchecked: 1), endAngle: Radian(_unchecked: -8)),
                ]
                arcs.forEach { arc in
                    let image = arc.transformed(by: map)
                    parameters.forEach { parameter in
                        #expect(near(image.point(at: Scale(parameter)), arc.point(at: Scale(parameter)).transformed(by: map)))
                    }
                    #expect(image.semiMajor >= image.semiMinor)
                    #expect(image.semiMinor >= 0)
                }
            }

            @Test
            func `A reflection reverses the sweep and a rotation keeps it`() {
                let arc = Geo.Ellipse.Arc(center: at(0, 0), semiMajor: 2, semiMinor: 1, rotation: .zero, startAngle: .zero, endAngle: Radian(_unchecked: 1))
                #expect(arc.isCounterClockwise)
                #expect(arc.transformed(by: Map(rows: [[0, -1, 0], [1, 0, 0]])).isCounterClockwise)
                #expect(!arc.transformed(by: Map(rows: [[1, 0, 0], [0, -1, 0]])).isCounterClockwise)
            }

            @Test(arguments: maps)
            func `A circular arc maps to an elliptical arc through the moved points`(map: Matrix<2, 3, Double>) {
                let arc = Geo.Arc(center: at(2, 1), radius: 3, startAngle: Radian(_unchecked: -0.5), endAngle: Radian(_unchecked: 4))
                let image = arc.transformed(by: map)
                parameters.forEach { parameter in
                    #expect(near(image.point(at: Scale(parameter)), arc.point(at: Scale(parameter)).transformed(by: map)))
                }
            }

            @Test
            func `A circular arc read as an elliptical arc has the same points`() {
                let arc = Geo.Arc(center: at(2, 1), radius: 3, startAngle: Radian(_unchecked: -0.5), endAngle: Radian(_unchecked: 4))
                let ellipse = Geo.Ellipse.Arc(arc)
                parameters.forEach { parameter in
                    #expect(near(ellipse.point(at: Scale(parameter)), arc.point(at: Scale(parameter))))
                }
                #expect(ellipse.startAngle == arc.startAngle)
                #expect(ellipse.endAngle == arc.endAngle)
            }

            @Test
            func `A singular map flattens an arc onto a segment and still moves its points`() {
                let map = Map(rows: [[1, 2, 1], [2, 4, 0]])
                let arc = Geo.Arc(center: at(0, 0), radius: 1, startAngle: .zero, endAngle: Radian(_unchecked: 5))
                let image = arc.transformed(by: map)
                #expect(abs(image.semiMinor.underlying) < 1e-12)
                parameters.forEach { parameter in
                    #expect(near(image.point(at: Scale(parameter)), arc.point(at: Scale(parameter)).transformed(by: map)))
                }
            }

            @Test
            func `A path keeps its subpaths, their order, their closedness and its lines and curves`() {
                let curve = Geo.Bezier.quadratic(from: at(1, 0), control: at(2, 2), to: at(3, 0))
                let arc = Geo.Arc(center: at(0, 0), radius: 1, startAngle: .zero, endAngle: .pi.full)
                let ellipse = Geo.Ellipse.Arc(center: at(0, 0), semiMajor: 2, semiMinor: 1, rotation: .zero, startAngle: .zero, endAngle: .pi.half)
                let path = Geo.Path(subpaths: [
                    .init(startPoint: at(0, 0), segments: [line(0, 0, 1, 0), .bezier(curve)], isClosed: true),
                    .init(startPoint: at(1, 0), segments: [.arc(arc), .ellipticalArc(ellipse)], isClosed: false),
                    .init(startPoint: at(9, 9), segments: [], isClosed: false),
                ])
                let map = Map(rows: [[2, 0, 10], [0, 3, 20]])
                let image: Geometry<Double, Page>.Path = path.transformed(by: map, to: Page.self)
                #expect(image.subpaths.map(\.isClosed) == [true, false, false])
                #expect(image.subpaths.map(\.segments.count) == [2, 2, 0])
                #expect(image.subpaths.map(\.startPoint) == [.init([10, 20]), .init([12, 20]), .init([28, 47])])
                #expect(image.subpaths[0].segments[0] == .line(.init(start: .init([10, 20]), end: .init([12, 20]))))
                #expect(image.subpaths[0].segments[1] == .bezier(curve.transformed(by: map, to: Page.self)))
                #expect(image.subpaths[1].segments[0] == .ellipticalArc(arc.transformed(by: map, to: Page.self)))
                #expect(image.subpaths[1].segments[1] == .ellipticalArc(ellipse.transformed(by: map, to: Page.self)))
            }

            @Test
            func `The identity returns lines and curves unchanged, and maps compose`() {
                let curve = Geo.Bezier.cubic(from: at(1, 0), control1: at(2, 2), control2: at(3, -1), to: at(4, 0))
                let path = Geo.Path(subpaths: [.init(startPoint: at(0, 0), segments: [line(0, 0, 1, 0), .bezier(curve)], isClosed: true)])
                #expect(path.transformed(by: .identity) == path)
                let first = Map(rows: [[2, 1, 3], [0, 4, -1]])
                let second = Map(rows: [[0, -1, 5], [1, 2, 8]])
                #expect(path.transformed(by: first).transformed(by: second) == path.transformed(by: second.multiplied(by: first)))
            }
        }
    }

    // MARK: - Flattening

    extension `Geometry.Path Tests` {
        @Suite
        struct `Flattening replaces curves by lines within a tolerance` {
            @Test
            func `Lines stay as they are`() throws {
                let path = Geo.Path(subpaths: [square(0, 4), .init(startPoint: at(1, 1), segments: [line(1, 1, 2, 5)], isClosed: false)])
                #expect(try path.flattened(tolerance: 0.5) == path)
            }

            @Test
            func `A curve becomes lines whose vertices lie on it and that stay within the tolerance`() throws {
                // (−1, 1), (0, −1), (1, 1) is the parabola y = x².
                let curve = Geo.Bezier.quadratic(from: at(-1, 1), control: at(0, -1), to: at(1, 1))
                let path = Geo.Path(subpaths: [.init(startPoint: at(-1, 1), segments: [.bezier(curve)], isClosed: true)])
                let flat = try path.flattened(tolerance: 0.001)
                let segments = flat.subpaths[0].segments
                #expect(flat.subpaths.count == 1)
                #expect(flat.subpaths[0].isClosed)
                #expect(flat.subpaths[0].startPoint == at(-1, 1))
                #expect(segments.count >= 16)
                var previous = at(-1, 1)
                segments.forEach { segment in
                    guard case .line(let piece) = segment else {
                        Issue.record("flattening left a curve")
                        return
                    }
                    #expect(piece.start == previous)
                    #expect(abs(piece.end[1] - piece.end[0] * piece.end[0]) < 1e-12)
                    #expect(piece.end[0] > piece.start[0])
                    // A chord of y = x² is furthest from it at its middle, by a quarter of its width squared.
                    let width = piece.end[0] - piece.start[0]
                    #expect(width * width / 4 <= 0.001)
                    previous = piece.end
                }
                #expect(previous == at(1, 1))
            }

            @Test
            func `A looser tolerance gives fewer lines, down to the chord`() throws {
                let curve = Geo.Bezier.quadratic(from: at(-1, 1), control: at(0, -1), to: at(1, 1))
                let path = Geo.Path(subpaths: [.init(startPoint: at(-1, 1), segments: [.bezier(curve)], isClosed: false)])
                let fine = try path.flattened(tolerance: 0.0001).segmentCount
                let coarse = try path.flattened(tolerance: 0.01).segmentCount
                #expect(fine > coarse)
                #expect(coarse > 1)
                #expect(try path.flattened(tolerance: 2).subpaths[0].segments == [line(-1, 1, 1, 1)])
            }

            @Test
            func `A control point beyond the chord's ends is not mistaken for flat`() throws {
                // All four control points are on the x axis, but the curve runs out to x = 3 and back.
                let curve = Geo.Bezier.cubic(from: at(0, 0), control1: at(8, 0), control2: at(-4, 0), to: at(1, 0))
                let path = Geo.Path(subpaths: [.init(startPoint: at(0, 0), segments: [.bezier(curve)], isClosed: false)])
                let flat = try path.flattened(tolerance: 0.01)
                #expect(flat.segmentCount > 2)
                var reach = 0.0
                flat.subpaths[0].segments.forEach { segment in
                    if case .line(let piece) = segment { reach = max(reach, piece.end[0]) }
                }
                #expect(reach > 2)
                #expect(flat.subpaths[0].endPoint == at(1, 0))
            }

            @Test
            func `An arc becomes chords with vertices on it and a sagitta within the tolerance`() throws {
                let path = Geo.Path(subpaths: [circle(radius: 10)])
                let flat = try path.flattened(tolerance: 0.01)
                let segments = flat.subpaths[0].segments
                #expect(flat.subpaths[0].isClosed)
                #expect(segments.count > 4)
                segments.forEach { segment in
                    guard case .line(let piece) = segment else {
                        Issue.record("flattening left a curve")
                        return
                    }
                    #expect(abs((piece.end[0] * piece.end[0] + piece.end[1] * piece.end[1]).squareRoot() - 10) < 1e-9)
                    let middle = (x: (piece.start[0] + piece.end[0]) / 2, y: (piece.start[1] + piece.end[1]) / 2)
                    #expect((middle.x * middle.x + middle.y * middle.y).squareRoot() >= 10 - 0.01)
                }
                #expect(near(try #require(flat.subpaths[0].endPoint), at(10, 0)))
            }

            @Test
            func `No chord spans more than a quarter turn however loose the tolerance`() throws {
                let path = Geo.Path(subpaths: [circle(radius: 1)])
                #expect(try path.flattened(tolerance: 100).segmentCount == 4)
                // At this tolerance the sagitta alone would allow three chords for the whole circle.
                #expect(try path.flattened(tolerance: 0.9).segmentCount == 4)
            }

            @Test
            func `An elliptical arc is flattened by its longer radius`() throws {
                let arc = Geo.Ellipse.Arc(center: at(0, 0), semiMajor: 10, semiMinor: 1, rotation: .zero, startAngle: .zero, endAngle: .pi.half)
                let path = Geo.Path(subpaths: [.init(startPoint: at(10, 0), segments: [.ellipticalArc(arc)], isClosed: false)])
                let flat = try path.flattened(tolerance: 0.01)
                flat.subpaths[0].segments.forEach { segment in
                    guard case .line(let piece) = segment else { return }
                    let middle = (x: (piece.start[0] + piece.end[0]) / 2 / 10, y: (piece.start[1] + piece.end[1]) / 2)
                    #expect(abs(piece.end[0] * piece.end[0] / 100 + piece.end[1] * piece.end[1] - 1) < 1e-9)
                    #expect((middle.x * middle.x + middle.y * middle.y).squareRoot() >= 1 - 0.001)
                }
                #expect(near(try #require(flat.subpaths[0].endPoint), at(0, 1)))
            }

            @Test
            func `A gap longer than the tolerance gets a joining line, a shorter one is closed up`() throws {
                let path = Geo.Path(subpaths: [.init(startPoint: at(0, 0), segments: [line(0, 0, 1, 0), line(1, 3, 2, 3)], isClosed: false)])
                #expect(try path.flattened(tolerance: 0.5).subpaths[0].segments == [line(0, 0, 1, 0), line(1, 0, 1, 3), line(1, 3, 2, 3)])
                #expect(try path.flattened(tolerance: 5).subpaths[0].segments == [line(0, 0, 1, 0), line(1, 0, 2, 3)])
                let late = Geo.Path(subpaths: [.init(startPoint: at(0, 0), segments: [line(4, 0, 5, 0)], isClosed: false)])
                #expect(try late.flattened(tolerance: 0.5).subpaths[0].segments == [line(0, 0, 4, 0), line(4, 0, 5, 0)])
            }

            @Test
            func `Segments that convert to no Bézier curve add nothing`() throws {
                let still = Geo.Arc(center: at(5, 5), radius: 1, startAngle: Radian(_unchecked: 1), endAngle: Radian(_unchecked: 1))
                let endless = Geo.Arc(center: at(5, 5), radius: 1, startAngle: .zero, endAngle: Radian(_unchecked: .infinity))
                let lone = Geo.Bezier(controlPoints: [at(7, 7)])
                let path = Geo.Path(subpaths: [.init(startPoint: at(0, 0), segments: [.arc(still), .arc(endless), .bezier(lone), line(0, 0, 1, 0)], isClosed: false)])
                #expect(try path.flattened(tolerance: 0.1).subpaths[0].segments == [line(0, 0, 1, 0)])
            }

            @Test(arguments: [0, -1, Double.nan, Double.infinity])
            func `A tolerance that is not positive and finite is refused`(tolerance: Double) {
                let path = Geo.Path(subpaths: [circle(radius: 1)])
                #expect(throws: Geo.Path.Error.tolerance) { try path.flattened(tolerance: .init(tolerance)) }
            }
        }
    }

    // MARK: - Winding

    extension `Geometry.Path Tests` {
        @Suite
        struct `The winding number counts counterclockwise turns around a point` {
            @Test
            func `A counterclockwise square winds once, a clockwise one minus once, and outside is zero`() {
                let forward = Geo.Path(subpaths: [square(0, 4)])
                let backward = Geo.Path(subpaths: [square(0, 4, clockwise: true)])
                #expect(forward.winding(around: at(2, 2)) == 1)
                #expect(backward.winding(around: at(2, 2)) == -1)
                [at(-1, 2), at(5, 2), at(2, -1), at(2, 5), at(5, 5)].forEach { outside in
                    #expect(forward.winding(around: outside) == 0)
                    #expect(backward.winding(around: outside) == 0)
                }
            }

            @Test
            func `Subpaths add, so the two rules part where the count is even`() {
                let nested = Geo.Path(subpaths: [square(0, 6), square(2, 4)])
                let holed = Geo.Path(subpaths: [square(0, 6), square(2, 4, clockwise: true)])
                #expect(nested.winding(around: at(3, 3)) == 2)
                #expect(nested.contains(at(3, 3), rule: .nonzero))
                #expect(!nested.contains(at(3, 3), rule: .evenodd))
                #expect(nested.contains(at(1, 1), rule: .evenodd))
                #expect(holed.winding(around: at(3, 3)) == 0)
                #expect(!holed.contains(at(3, 3), rule: .nonzero))
                #expect(!holed.contains(at(3, 3), rule: .evenodd))
                #expect(holed.contains(at(1, 1), rule: .nonzero))
            }

            @Test
            func `A pentagram winds twice around its centre and once around its points`() {
                let star = Geo.Path(subpaths: [polygon([(0, 10), (-5.878, -8.09), (9.511, 3.09), (-9.511, 3.09), (5.878, -8.09)])])
                #expect(star.winding(around: at(0, 0)) == 2)
                #expect(star.winding(around: at(0, 8)) == 1)
                #expect(star.contains(at(0, 0), rule: .nonzero))
                #expect(!star.contains(at(0, 0), rule: .evenodd))
                #expect(star.contains(at(0, 8), rule: .evenodd))
            }

            @Test
            func `An open subpath counts as closed by a straight line`() {
                let open = Geo.Path(subpaths: [.init(startPoint: at(0, 0), segments: [line(0, 0, 4, 0), line(4, 0, 0, 4)], isClosed: false)])
                #expect(open.winding(around: at(1, 1)) == 1)
                #expect(open.winding(around: at(3, 3)) == 0)
            }

            @Test
            func `A gap between segments counts as a straight line`() {
                // The right side, from (4, 0) up to (4, 4), is a gap between the two segments.
                let gapped = Geo.Path(subpaths: [.init(startPoint: at(0, 0), segments: [line(0, 0, 4, 0), line(4, 4, 0, 4)], isClosed: true)])
                #expect(gapped.winding(around: at(2, 2)) == 1)
                #expect(gapped.winding(around: at(3.999, 2)) == 1)
                #expect(gapped.winding(around: at(4.001, 2)) == 0)
                // Here the first segment starts away from the subpath's start, at the top of the left side.
                let late = Geo.Path(subpaths: [.init(startPoint: at(0, 0), segments: [line(0, 4, 4, 4), line(4, 4, 4, 0)], isClosed: true)])
                #expect(late.winding(around: at(2, 2)) == -1)
                #expect(late.winding(around: at(-0.001, 2)) == 0)
            }

            @Test(arguments: [0.0, 0.3, 0.7853981633974483, 1.2, 2.5, 3.9, 5.5])
            func `A circular arc is followed exactly, not through a Bézier or a chord`(direction: Double) {
                let path = Geo.Path(subpaths: [circle(radius: 1)])
                let inside = at(0.999999 * Double.cos(direction), 0.999999 * Double.sin(direction))
                let outside = at(1.000001 * Double.cos(direction), 1.000001 * Double.sin(direction))
                #expect(path.winding(around: inside) == 1)
                #expect(path.winding(around: outside) == 0)
            }

            @Test(arguments: [-0.5, 0.9, 2.0, 4.1])
            func `An arc is followed exactly wherever it starts`(start: Double) {
                // The pieces of this arc straddle the axis directions, where the circle reaches furthest.
                let arc = Geo.Arc(center: at(0, 0), radius: 1, startAngle: Radian(_unchecked: start), endAngle: Radian(_unchecked: start + 2 * Double.pi))
                let path = Geo.Path(subpaths: [.init(startPoint: arc.startPoint, segments: [.arc(arc)], isClosed: true)])
                [(1.0, 0.0), (0, 1), (-1, 0), (0, -1)].forEach { unit in
                    #expect(path.winding(around: at(0.999 * unit.0, 0.999 * unit.1)) == 1)
                    #expect(path.winding(around: at(1.001 * unit.0, 1.001 * unit.1)) == 0)
                }
            }

            @Test
            func `A curve that is one point winds around nothing, even that point`() {
                let still = Geo.Bezier.cubic(from: at(1, 1), control1: at(1, 1), control2: at(1, 1), to: at(1, 1))
                let path = Geo.Path(subpaths: [.init(startPoint: at(1, 1), segments: [.bezier(still)], isClosed: true)])
                #expect(path.winding(around: at(1, 1)) == 0)
                #expect(path.winding(around: at(0, 0)) == 0)
            }

            @Test
            func `An arc counts every turn it makes, with its sign`() {
                #expect(Geo.Path(subpaths: [circle(radius: 1, turns: 2)]).winding(around: at(0.2, 0.3)) == 2)
                #expect(Geo.Path(subpaths: [circle(radius: 1, turns: -1)]).winding(around: at(0.2, 0.3)) == -1)
                #expect(Geo.Path(subpaths: [circle(radius: 1, turns: 2)]).winding(around: at(1.2, 0.3)) == 0)
                #expect(!Geo.Path(subpaths: [circle(radius: 1, turns: 2)]).contains(at(0.2, 0.3), rule: .evenodd))
            }

            @Test
            func `A half disc is bounded by its arc and its closing line`() {
                let arc = Geo.Arc(center: at(0, 0), radius: 1, startAngle: .zero, endAngle: .pi.full)
                let path = Geo.Path(subpaths: [.init(startPoint: at(1, 0), segments: [.arc(arc)], isClosed: true)])
                #expect(path.winding(around: at(0, 0.5)) == 1)
                #expect(path.winding(around: at(0.7, 0.7)) == 1)
                #expect(path.winding(around: at(0.71, 0.71)) == 0)
                #expect(path.winding(around: at(0, -0.001)) == 0)
            }

            @Test
            func `A rotated elliptical arc is followed exactly`() {
                let turn = 0.5
                let arc = Geo.Ellipse.Arc(center: at(3, 4), semiMajor: 2, semiMinor: 1, rotation: Radian(_unchecked: turn), startAngle: .zero, endAngle: .pi.two)
                let path = Geo.Path(subpaths: [.init(startPoint: arc.startPoint, segments: [.ellipticalArc(arc)], isClosed: true)])
                let major = (x: Double.cos(turn), y: Double.sin(turn))
                let minor = (x: -Double.sin(turn), y: Double.cos(turn))
                #expect(path.winding(around: at(3 + 1.99999 * major.x, 4 + 1.99999 * major.y)) == 1)
                #expect(path.winding(around: at(3 + 2.00001 * major.x, 4 + 2.00001 * major.y)) == 0)
                #expect(path.winding(around: at(3 - 0.99999 * minor.x, 4 - 0.99999 * minor.y)) == 1)
                #expect(path.winding(around: at(3 - 1.00001 * minor.x, 4 - 1.00001 * minor.y)) == 0)
            }

            @Test(arguments: [-0.9, -0.5, -0.001, 0.25, 0.75])
            func `A Bézier curve is followed exactly`(x: Double) {
                // The parabola y = x² from (−1, 1) to (1, 1), closed along y = 1.
                let curve = Geo.Bezier.quadratic(from: at(-1, 1), control: at(0, -1), to: at(1, 1))
                let path = Geo.Path(subpaths: [.init(startPoint: at(-1, 1), segments: [.bezier(curve)], isClosed: true)])
                #expect(path.winding(around: at(x, x * x + 1e-9)) == 1)
                #expect(path.winding(around: at(x, x * x - 1e-9)) == 0)
                #expect(path.winding(around: at(x, 1 + 1e-9)) == 0)
            }

            @Test
            func `A cubic with a loop winds around the loop`() {
                let curve = Geo.Bezier.cubic(from: at(0, 0), control1: at(4, 3), control2: at(-3, 3), to: at(1, 0))
                let path = Geo.Path(subpaths: [.init(startPoint: at(0, 0), segments: [.bezier(curve)], isClosed: true)])
                let flat = Geo.Path(subpaths: [polygon([(0, 0), (4, 3), (-3, 3), (1, 0)])])
                #expect(path.winding(around: at(0.5, 0.2)) == -1)
                #expect(path.winding(around: at(0.5, 1.6)) == 1)
                #expect(flat.winding(around: at(0.5, 2.5)) == 1)
                #expect(path.winding(around: at(0.5, 2.5)) == 0)
            }

            @Test(arguments: maps)
            func `Moving path and point together keeps the number, and a reflection negates it`(map: Matrix<2, 3, Double>) {
                let curve = Geo.Bezier.cubic(from: at(4, 0), control1: at(4, 3), control2: at(1, 4), to: at(0, 4))
                let arc = Geo.Arc(center: at(0, 0), radius: 4, startAngle: .pi.half, endAngle: Radian(_unchecked: 1.5 * Double.pi))
                let path = Geo.Path(subpaths: [.init(startPoint: at(4, 0), segments: [.bezier(curve), .arc(arc), line(0, -4, 4, 0)], isClosed: true), square(-1, 1)])
                let sign = map.linear.determinant < 0 ? -1 : 1
                let moved = path.transformed(by: map)
                [at(0, 0), at(2, 2), at(-3, 0.5), at(3.2, 3.2), at(-5, 0), at(1.5, -1.5), at(3, -2)].forEach { point in
                    #expect(moved.winding(around: point.transformed(by: map)).turns == sign * path.winding(around: point).turns)
                }
                #expect(path.winding(around: at(0, 0)) == 2)
                #expect(path.winding(around: at(3.2, 3.2)) == 0)
            }

            @Test
            func `Nothing winds around a point that is not finite, and an empty path winds around nothing`() {
                let path = Geo.Path(subpaths: [square(0, 4), circle(radius: 3)])
                #expect(path.winding(around: at(.nan, 1)) == 0)
                #expect(path.winding(around: at(1, .infinity)) == 0)
                #expect(Geo.Path(subpaths: []).winding(around: at(0, 0)) == 0)
                #expect(Geo.Path(subpaths: [.init(startPoint: at(0, 0), segments: [], isClosed: true)]).winding(around: at(0, 0)) == 0)
            }

            @Test(arguments: Winding.Rule.allCases)
            func `Containment is the rule applied to the winding number`(rule: Winding.Rule) {
                let path = Geo.Path(subpaths: [square(0, 6), square(2, 4), circle(radius: 1, turns: -1)])
                [at(3, 3), at(1, 1), at(0.5, 0.5), at(-0.5, -0.5), at(9, 9)].forEach { point in
                    #expect(path.contains(point, rule: rule) == rule.contains(path.winding(around: point)))
                }
            }
        }
    }
#endif
