#if Affine
    public import Direction
    public import Matrix
    import Affine
    import Displacement
    import Point
    import Vector
    public import Tagged
    import Scale
    import Angle
    import Trigonometry

    public import Numeric

    extension Geometry {

        public struct Path {

            public var subpaths: [Subpath]

            @inlinable
            public init(subpaths: consuming [Subpath]) {
                self.subpaths = subpaths
            }
        }
    }

    extension Geometry.Path: Sendable where Scalar: Sendable {}
    extension Geometry.Path: Equatable where Scalar: Equatable {}
    extension Geometry.Path: Hashable where Scalar: Hashable {}

    #if !hasFeature(Embedded)
        extension Geometry.Path: Codable where Scalar: Codable {}
    #endif

    extension Geometry.Path {

        public struct Subpath {

            public var startPoint: Geometry.Point<2>

            public var segments: [Segment]

            public var isClosed: Bool

            @inlinable
            public init(
                startPoint: consuming Geometry.Point<2>,
                segments: consuming [Segment],
                isClosed: Bool = false
            ) {
                self.startPoint = startPoint
                self.segments = segments
                self.isClosed = isClosed
            }
        }
    }

    extension Geometry.Path.Subpath: Sendable where Scalar: Sendable {}
    extension Geometry.Path.Subpath: Equatable where Scalar: Equatable {}
    extension Geometry.Path.Subpath: Hashable where Scalar: Hashable {}

    #if !hasFeature(Embedded)
        extension Geometry.Path.Subpath: Codable where Scalar: Codable {}
    #endif

    extension Geometry.Path {

        public enum Segment {

            case line(Geometry.Line.Segment)

            case bezier(Geometry.Bezier)

            case arc(Geometry.Arc)

            case ellipticalArc(Geometry.Ellipse.Arc)
        }
    }

    extension Geometry.Path.Segment: Sendable where Scalar: Sendable {}
    extension Geometry.Path.Segment: Equatable where Scalar: Equatable {}
    extension Geometry.Path.Segment: Hashable where Scalar: Hashable {}

    #if !hasFeature(Embedded)
        extension Geometry.Path.Segment: Codable where Scalar: Codable {}
    #endif

    extension Geometry.Path.Segment where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public var startPoint: Geometry.Point<2>? {
            switch self {
            case .line(let seg): return seg.start
            case .bezier(let bez): return bez.startPoint
            case .arc(let arc): return arc.startPoint
            case .ellipticalArc(let arc): return arc.startPoint
            }
        }

        @inlinable
        public var endPoint: Geometry.Point<2>? {
            switch self {
            case .line(let seg): return seg.end
            case .bezier(let bez): return bez.endPoint
            case .arc(let arc): return arc.endPoint
            case .ellipticalArc(let arc): return arc.endPoint
            }
        }
    }

    extension Geometry.Path.Segment where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public init(
            from start: Geometry.Point<2>,
            to end: Geometry.Point<2>,
            rx: Geometry.Length,
            ry: Geometry.Length,
            xAxisRotation: Radian<Scalar>,
            extent: Geometry.Ellipse.Arc.Extent,
            direction: Geometry.Ellipse.Arc.Direction
        ) {
            let arc = Geometry.Ellipse.Arc(
                from: start,
                to: end,
                rx: rx,
                ry: ry,
                xAxisRotation: xAxisRotation,
                extent: extent,
                direction: direction
            )
            self = arc.map { .ellipticalArc($0) } ?? .line(Geometry.Line.Segment(start: start, end: end))
        }
    }

    extension Array {

        @inlinable
        public init<Scalar: BinaryFloatingPoint & Numeric.Transcendental, Space>(
            segment: Geometry<Scalar, Space>.Path.Segment
        ) where Element == Geometry<Scalar, Space>.Bezier {
            switch segment {
            case .line(let seg):
                self = [.linear(from: seg.start, to: seg.end)]

            case .bezier(let bez):
                self = [bez]

            case .arc(let arc):
                self.init(arc: arc)

            case .ellipticalArc(let arc):
                self.init(ellipticalArc: arc)
            }
        }
    }

    extension Geometry.Path.Segment where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public func toBeziers() -> [Geometry.Bezier] { .init(segment: self) }
    }

    extension Geometry.Path {

        @inlinable
        public var isEmpty: Bool { subpaths.isEmpty }

        @inlinable
        public var segmentCount: Int {
            subpaths.reduce(0) { $0 + $1.segments.count }
        }
    }

    extension Array where Element: RangeReplaceableCollection {

        @inlinable
        public init<Scalar: BinaryFloatingPoint & Numeric.Transcendental, Space>(
            path: Geometry<Scalar, Space>.Path
        ) where Element == [Geometry<Scalar, Space>.Bezier] {
            self = path.subpaths.map { subpath in
                var beziers = subpath.segments.flatMap { [Geometry<Scalar, Space>.Bezier](segment: $0) }
                if subpath.isClosed, let last = beziers.last?.endPoint {
                    if last != subpath.startPoint {
                        beziers.append(.linear(from: last, to: subpath.startPoint))
                    }
                }
                return beziers
            }
        }
    }

    extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public func toBeziers() -> [[Geometry.Bezier]] { .init(path: self) }

        @inlinable
        public var boundingBox: Geometry.Rectangle? {

            let allBeziers = toBeziers().flatMap { $0 }
            guard let first = allBeziers.first?.boundingBoxConservative else { return nil }
            return allBeziers.dropFirst().reduce(first) { rect, bez in
                guard let bezRect = bez.boundingBoxConservative else { return rect }
                return rect.union(bezRect)
            }
        }
    }

    extension Geometry.Path.Subpath {

        @inlinable
        public var isEmpty: Bool { segments.isEmpty }
    }

    extension Geometry.Path.Subpath where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public var endPoint: Geometry.Point<2>? {
            segments.last?.endPoint ?? startPoint
        }
    }

    extension Geometry.Path.Subpath where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public func length(bezierSegments: Int = 100) -> Geometry.ArcLength {
            var total: Geometry.ArcLength = .zero
            for segment in segments {
                switch segment {
                case .line(let seg):
                    total += Geometry.length(of: seg)

                case .bezier(let bez):
                    total += bez.length(segments: bezierSegments)

                case .arc(let arc):
                    total += arc.length

                case .ellipticalArc(let arc):
                    total += arc.length(segments: bezierSegments)
                }
            }
            if isClosed, let end = endPoint, end != startPoint {
                total += end.distance(to: startPoint)
            }
            return total
        }
    }

    extension Geometry.Path {

        @inlinable
        public static func polygon(vertices: [Geometry.Point<2>]) -> Self? {
            guard vertices.count >= 3 else { return nil }
            var segments: [Segment] = []
            for i in vertices.indices.dropLast() {
                segments.append(.line(.init(start: vertices[i], end: vertices[i + 1])))
            }
            return Self(subpaths: [
                .init(startPoint: vertices[0], segments: segments, isClosed: true)
            ])
        }

        @inlinable
        public static func polyline(vertices: [Geometry.Point<2>]) -> Self? {
            guard vertices.count >= 2 else { return nil }
            var segments: [Segment] = []
            for i in vertices.indices.dropLast() {
                segments.append(.line(.init(start: vertices[i], end: vertices[i + 1])))
            }
            return Self(subpaths: [
                .init(startPoint: vertices[0], segments: segments, isClosed: false)
            ])
        }
    }

    extension Geometry.Path where Scalar: BinaryFloatingPoint {

        /// A rectangle's border as one closed subpath, counterclockwise from its lower-left corner, with
        /// every corner a quarter circle of `radius`, held to half the shorter side.
        @inlinable
        public init(_ rectangle: Geometry.Rectangle, radius: Geometry.Radius = .init(0)) {
            self.init(rectangle, lowerLeft: radius, lowerRight: radius, upperRight: radius, upperLeft: radius)
        }

        /// A rectangle's border as one closed subpath, counterclockwise from its lower-left corner, with
        /// each corner a quarter circle of its own radius, held to half the shorter side. A corner whose
        /// radius is not positive, or not a number, is square.
        @inlinable
        public init(
            _ rectangle: Geometry.Rectangle,
            lowerLeft: Geometry.Radius,
            lowerRight: Geometry.Radius,
            upperRight: Geometry.Radius,
            upperLeft: Geometry.Radius
        ) {
            let left: Scalar = rectangle.llx.underlying
            let lower: Scalar = rectangle.lly.underlying
            let right: Scalar = rectangle.urx.underlying
            let upper: Scalar = rectangle.ury.underlying
            let limit: Scalar = Swift.min(right - left, upper - lower) / 2

            func held(_ radius: Geometry.Radius) -> Scalar {
                radius.underlying > 0 ? Swift.min(radius.underlying, limit) : 0
            }
            func at(_ x: Scalar, _ y: Scalar) -> Geometry.Point<2> {
                Geometry.Point(x: Geometry.X(x), y: Geometry.Y(y))
            }
            func side(_ start: Geometry.Point<2>, _ end: Geometry.Point<2>) -> Segment {
                .line(Geometry.Line.Segment(start: start, end: end))
            }

            let (ll, lr, ur, ul) = (held(lowerLeft), held(lowerRight), held(upperRight), held(upperLeft))
            let quarter: Radian<Scalar> = .pi.half
            var segments: [Segment] = []
            func corner(_ x: Scalar, _ y: Scalar, _ round: Scalar, from start: Radian<Scalar>) {
                guard round > 0 else { return }
                segments.append(.arc(.quarterCircle(center: at(x, y), radius: Geometry.Radius(round), startAngle: start)))
            }
            segments.append(side(at(left + ll, lower), at(right - lr, lower)))
            corner(right - lr, lower + lr, lr, from: .zero - quarter)
            segments.append(side(at(right, lower + lr), at(right, upper - ur)))
            corner(right - ur, upper - ur, ur, from: .zero)
            segments.append(side(at(right - ur, upper), at(left + ul, upper)))
            corner(left + ul, upper - ul, ul, from: quarter)
            segments.append(side(at(left, upper - ul), at(left, lower + ll)))
            corner(left + ll, lower + ll, ll, from: quarter + quarter)
            self.init(subpaths: [Subpath(startPoint: at(left + ll, lower), segments: segments, isClosed: true)])
        }

        @inlinable
        public init(_ circle: Geometry.Circle) {
            let right = Geometry.Point(x: Geometry.X(circle.center.x.underlying + circle.radius.underlying), y: circle.center.y)
            self.init(subpaths: [
                Subpath(
                    startPoint: right,
                    segments: [.arc(.fullCircle(center: circle.center, radius: circle.radius))],
                    isClosed: true
                )
            ])
        }

        /// The closed smooth curve through the vertices in order and back to the first: the uniform
        /// Catmull–Rom spline, one cubic Bézier from each vertex to the next, whose tangent at a vertex is
        /// half the chord from the vertex before it to the vertex after it. Nil for fewer than three vertices.
        @inlinable
        public static func loop(through vertices: [Geometry.Point<2>]) -> Self? {
            guard vertices.count >= 3 else { return nil }
            let next = Array(vertices.dropFirst() + vertices.prefix(1))
            let before = Array(vertices.suffix(1) + vertices.dropLast())
            let after = Array(next.dropFirst() + next.prefix(1))
            func at(_ x: Scalar, _ y: Scalar) -> Geometry.Point<2> { Geometry.Point<2>([x, y]) }
            let segments = zip(zip(before, vertices), zip(next, after)).map { pair, ahead -> Segment in
                let ((before, from), (to, after)) = (pair, ahead)
                return .bezier(
                    .cubic(
                        from: from,
                        control1: at(from[0] + (to[0] - before[0]) / 6, from[1] + (to[1] - before[1]) / 6),
                        control2: at(to[0] - (after[0] - from[0]) / 6, to[1] - (after[1] - from[1]) / 6),
                        to: to
                    )
                )
            }
            return Self(subpaths: [Subpath(startPoint: vertices[0], segments: segments, isClosed: true)])
        }
    }

    extension Geometry.Path.Segment {

        @inlinable
        public func map<Result, E: Swift::Error>(
            _ transform: (Scalar) throws(E) -> Result
        ) throws(E) -> Geometry<Result, Space>.Path.Segment {
            switch self {
            case .line(let seg):
                return .line(try seg.map { point throws(E) in try point.map(transform) })

            case .bezier(let bez):
                return .bezier(try bez.map(transform))

            case .arc(let arc):
                return .arc(try arc.map(transform))

            case .ellipticalArc(let arc):
                return .ellipticalArc(try arc.map(transform))
            }
        }
    }

    extension Geometry.Path.Subpath {

        @inlinable
        public func map<Result, E: Swift::Error>(
            _ transform: (Scalar) throws(E) -> Result
        ) throws(E) -> Geometry<Result, Space>.Path.Subpath {
            .init(
                startPoint: try startPoint.map(transform),
                segments: try segments.map {
                    (
                        segment: Geometry<Scalar, Space>.Path.Segment
                    ) throws(E) -> Geometry<Result, Space>.Path.Segment in
                    try segment.map(transform)
                },
                isClosed: isClosed
            )
        }
    }

    extension Geometry.Path {

        @inlinable
        public func map<Result, E: Swift::Error>(
            _ transform: (Scalar) throws(E) -> Result
        ) throws(E) -> Geometry<Result, Space>.Path {
            .init(
                subpaths: try subpaths.map {
                    (
                        subpath: Geometry<Scalar, Space>.Path.Subpath
                    ) throws(E) -> Geometry<Result, Space>.Path.Subpath in
                    try subpath.map(transform)
                }
            )
        }
    }

    extension Geometry.Path.Segment where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public func transformed<Target>(
            by map: Matrix::Matrix<2, 3, Scalar>,
            to space: Target.Type
        ) -> Geometry<Scalar, Target>.Path.Segment {
            switch self {
            case .line(let segment):
                return .line(
                    .init(
                        start: segment.start.transformed(by: map, to: space),
                        end: segment.end.transformed(by: map, to: space)
                    )
                )

            case .bezier(let bezier):
                return .bezier(bezier.transformed(by: map, to: space))

            case .arc(let arc):
                return .ellipticalArc(arc.transformed(by: map, to: space))

            case .ellipticalArc(let arc):
                return .ellipticalArc(arc.transformed(by: map, to: space))
            }
        }

        @inlinable
        public func transformed(by map: Matrix::Matrix<2, 3, Scalar>) -> Self {
            transformed(by: map, to: Space.self)
        }
    }

    extension Geometry.Path.Subpath where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public func transformed<Target>(
            by map: Matrix::Matrix<2, 3, Scalar>,
            to space: Target.Type
        ) -> Geometry<Scalar, Target>.Path.Subpath {
            .init(
                startPoint: startPoint.transformed(by: map, to: space),
                segments: segments.map { $0.transformed(by: map, to: space) },
                isClosed: isClosed
            )
        }

        @inlinable
        public func transformed(by map: Matrix::Matrix<2, 3, Scalar>) -> Self {
            transformed(by: map, to: Space.self)
        }
    }

    extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public func transformed<Target>(
            by map: Matrix::Matrix<2, 3, Scalar>,
            to space: Target.Type
        ) -> Geometry<Scalar, Target>.Path {
            .init(subpaths: subpaths.map { $0.transformed(by: map, to: space) })
        }

        @inlinable
        public func transformed(by map: Matrix::Matrix<2, 3, Scalar>) -> Self {
            transformed(by: map, to: Space.self)
        }
    }

    extension Geometry.Path.Subpath where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// The subpath as one continuous run of vertices, curves made straight to within `tolerance`.
        ///
        /// `smooth` marks a vertex that flattening put inside a curve; every other vertex is a corner of the path.
        @inlinable
        func polyline(tolerance: Scalar) -> [(x: Scalar, y: Scalar, smooth: Bool)] {
            var result: [(x: Scalar, y: Scalar, smooth: Bool)] = [(startPoint[0], startPoint[1], false)]

            func bridge(to point: (x: Scalar, y: Scalar)) {
                guard let last = result.last else { return }
                let gap = (x: point.x - last.x, y: point.y - last.y)
                if (gap.x * gap.x + gap.y * gap.y).squareRoot() > tolerance {
                    result.append((point.x, point.y, false))
                }
            }

            func run(along arc: Geometry.Ellipse.Arc) {
                guard let steps = arc.steps(tolerance: tolerance) else { return }
                let frame = arc.frame
                let start = arc.startAngle.underlying
                let sweep = arc.sweep.underlying
                func point(at angle: Scalar) -> (x: Scalar, y: Scalar) {
                    let cosine = Scalar.cos(angle)
                    let sine = Scalar.sin(angle)
                    return (
                        frame.center.x + frame.major.x * cosine + frame.minor.x * sine,
                        frame.center.y + frame.major.y * cosine + frame.minor.y * sine
                    )
                }
                bridge(to: point(at: start))
                var step = 1
                while step < steps {
                    let inside = point(at: start + sweep * Scalar(step) / Scalar(steps))
                    result.append((inside.x, inside.y, true))
                    step += 1
                }
                let end = point(at: arc.endAngle.underlying)
                result.append((end.x, end.y, false))
            }

            for segment in segments {
                switch segment {
                case .line(let line):
                    bridge(to: (line.start[0], line.start[1]))
                    result.append((line.end[0], line.end[1], false))

                case .bezier(let bezier):
                    let points = bezier.controlPoints.map { (x: $0[0], y: $0[1]) }
                    guard points.count > 1, let first = points.first, let last = points.last else { continue }
                    bridge(to: first)
                    if points.allSatisfy({ $0.x.isFinite && $0.y.isFinite }) {
                        Geometry.Bezier.flatten(points, tolerance: tolerance, depth: 16, into: &result)
                    }
                    result.append((last.x, last.y, false))

                case .arc(let arc):
                    run(along: Geometry.Ellipse.Arc(arc))

                case .ellipticalArc(let arc):
                    run(along: arc)
                }
            }
            return result
        }

        @inlinable
        func flattened(tolerance: Scalar) -> Self {
            var lines: [Geometry.Path.Segment] = []
            var previous = startPoint
            for vertex in polyline(tolerance: tolerance).dropFirst() {
                let next = Geometry.Point<2>([vertex.x, vertex.y])
                lines.append(.line(.init(start: previous, end: next)))
                previous = next
            }
            return Self(startPoint: startPoint, segments: lines, isClosed: isClosed)
        }
    }

    extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public func flattened(tolerance: Geometry.Length) throws(Error) -> Self {
            let allowance = tolerance.underlying
            guard allowance.isFinite, allowance > 0 else { throw .tolerance }
            return Self(subpaths: subpaths.map { $0.flattened(tolerance: allowance) })
        }
    }

    extension Geometry.Path.Subpath where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// The signed number of times the subpath, closed by a straight line, turns around a finite point.
        ///
        /// A piece of a curve is replaced by its chord once the point is outside the box around it: for a Bézier
        /// curve the box around its control points, for an arc the box around its two ends and the point where
        /// the tangents at those ends meet.
        @inlinable
        func turns(around target: (x: Scalar, y: Scalar)) -> Int {
            var turns = 0
            let first = (x: startPoint[0], y: startPoint[1])
            var current = first

            func edge(to next: (x: Scalar, y: Scalar)) {
                let side = (next.x - current.x) * (target.y - current.y) - (target.x - current.x) * (next.y - current.y)
                if current.y <= target.y {
                    if next.y > target.y, side > 0 { turns += 1 }
                } else if next.y <= target.y, side < 0 {
                    turns -= 1
                }
                current = next
            }

            /// Whether the target lies outside the box around the points, or the box is a single point.
            func clears(_ points: [(x: Scalar, y: Scalar)]) -> Bool {
                guard var low = points.first else { return true }
                var high = low
                for point in points {
                    low = (min(low.x, point.x), min(low.y, point.y))
                    high = (max(high.x, point.x), max(high.y, point.y))
                }
                if low.x == high.x, low.y == high.y { return true }
                return target.x < low.x || target.x > high.x || target.y < low.y || target.y > high.y
            }

            func walk(_ points: [(x: Scalar, y: Scalar)], depth: Int) {
                guard let last = points.last else { return }
                if depth == 0 || clears(points) {
                    edge(to: last)
                    return
                }
                let halves = Geometry.Bezier.split(points)
                walk(halves.left, depth: depth - 1)
                walk(halves.right, depth: depth - 1)
            }

            func run(along arc: Geometry.Ellipse.Arc) {
                guard let quarters = arc.quarters else { return }
                let frame = arc.frame
                let start = arc.startAngle.underlying
                let sweep = arc.sweep.underlying
                func point(at angle: Scalar, over scale: Scalar = 1) -> (x: Scalar, y: Scalar) {
                    let cosine = Scalar.cos(angle) / scale
                    let sine = Scalar.sin(angle) / scale
                    return (
                        frame.center.x + frame.major.x * cosine + frame.minor.x * sine,
                        frame.center.y + frame.major.y * cosine + frame.minor.y * sine
                    )
                }
                func piece(from: Scalar, to: Scalar, depth: Int) {
                    let end = point(at: to)
                    let middle = from / 2 + to / 2
                    let corner = point(at: middle, over: Scalar.cos((to - from) / 2))
                    if depth == 0 || clears([current, corner, end]) {
                        edge(to: end)
                        return
                    }
                    piece(from: from, to: middle, depth: depth - 1)
                    piece(from: middle, to: to, depth: depth - 1)
                }
                edge(to: point(at: start))
                var index = 0
                while index < quarters {
                    let from = index == 0 ? start : start + sweep * Scalar(index) / Scalar(quarters)
                    let to = index + 1 == quarters ? arc.endAngle.underlying : start + sweep * Scalar(index + 1) / Scalar(quarters)
                    piece(from: from, to: to, depth: 32)
                    index += 1
                }
            }

            for segment in segments {
                switch segment {
                case .line(let line):
                    edge(to: (line.start[0], line.start[1]))
                    edge(to: (line.end[0], line.end[1]))

                case .bezier(let bezier):
                    let points = bezier.controlPoints.map { (x: $0[0], y: $0[1]) }
                    guard points.count > 1, let first = points.first, let last = points.last else { continue }
                    edge(to: first)
                    if points.allSatisfy({ $0.x.isFinite && $0.y.isFinite }) {
                        walk(points, depth: 32)
                    } else {
                        edge(to: last)
                    }

                case .arc(let arc):
                    run(along: Geometry.Ellipse.Arc(arc))

                case .ellipticalArc(let arc):
                    run(along: arc)
                }
            }
            edge(to: first)
            return turns
        }
    }

    extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public func winding(around point: Geometry.Point<2>) -> Direction::Winding.Number {
            let target = (x: point[0], y: point[1])
            guard target.x.isFinite, target.y.isFinite else { return .zero }
            var turns = 0
            for subpath in subpaths { turns += subpath.turns(around: target) }
            return Direction::Winding.Number(turns)
        }

        @inlinable
        public func contains(_ point: Geometry.Point<2>, rule: Direction::Winding.Rule) -> Bool {
            rule.contains(winding(around: point))
        }
    }

    extension Geometry.Path.Subpath where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// A closed counterclockwise or clockwise run of straight lines through the corners, as given.
        @inlinable
        static func ring(_ corners: [(x: Scalar, y: Scalar)]) -> Self {
            let points = corners.map { Geometry.Point<2>([$0.x, $0.y]) }
            var lines: [Geometry.Path.Segment] = []
            for index in points.indices.dropFirst() {
                lines.append(.line(.init(start: points[index - 1], end: points[index])))
            }
            return Self(startPoint: points[0], segments: lines, isClosed: true)
        }

        /// The pie slice around `center` that starts at `angle` and sweeps counterclockwise.
        @inlinable
        static func sector(
            center: (x: Scalar, y: Scalar),
            radius: Scalar,
            from angle: Scalar,
            sweep: Scalar
        ) -> Self {
            let middle = Geometry.Point<2>([center.x, center.y])
            let arc = Geometry.Arc(
                center: middle,
                radius: Geometry.Radius(radius),
                startAngle: Radian(_unchecked: angle),
                endAngle: Radian(_unchecked: angle + sweep)
            )
            return Self(
                startPoint: middle,
                segments: [.line(.init(start: middle, end: arc.startPoint)), .arc(arc)],
                isClosed: true
            )
        }

        /// Appends the closed counterclockwise pieces whose union is this subpath stroked.
        ///
        /// The left normal of a direction is (−y, x). The body of a straight run goes out along its right side and
        /// back along its left. A left turn opens the gap a join fills on the right side, a right turn on the left.
        @inlinable
        func outline(
            _ stroke: Geometry.Path.Stroke,
            half: Scalar,
            tolerance: Scalar,
            into pieces: inout [Self]
        ) {
            guard !segments.isEmpty else { return }

            var vertices: [(x: Scalar, y: Scalar, smooth: Bool)] = []
            for vertex in polyline(tolerance: tolerance) {
                guard let last = vertices.last else {
                    vertices.append(vertex)
                    continue
                }
                let gap = (x: vertex.x - last.x, y: vertex.y - last.y)
                let length = (gap.x * gap.x + gap.y * gap.y).squareRoot()
                if length > 0, length.isFinite { vertices.append(vertex) }
            }
            if isClosed, vertices.count > 1, let first = vertices.first, let last = vertices.last {
                let gap = (x: first.x - last.x, y: first.y - last.y)
                if !((gap.x * gap.x + gap.y * gap.y).squareRoot() > tolerance) { vertices.removeLast() }
            }
            guard let first = vertices.first, let last = vertices.last else { return }

            guard vertices.count > 1 else {
                switch stroke.cap {
                case .butt:
                    break

                case .round:
                    let center = Geometry.Point<2>([first.x, first.y])
                    let circle = Geometry.Arc.fullCircle(center: center, radius: Geometry.Radius(half))
                    pieces.append(Self(startPoint: circle.startPoint, segments: [.arc(circle)], isClosed: true))

                case .square:
                    pieces.append(
                        Self.ring([
                            (first.x - half, first.y - half), (first.x + half, first.y - half),
                            (first.x + half, first.y + half), (first.x - half, first.y + half),
                        ])
                    )
                }
                return
            }

            let count = vertices.count
            let edges = isClosed ? count : count - 1
            var directions: [(x: Scalar, y: Scalar)] = []
            for index in vertices.indices.prefix(edges) {
                let from = vertices[index]
                let to = vertices[(index + 1) % count]
                let gap = (x: to.x - from.x, y: to.y - from.y)
                let length = (gap.x * gap.x + gap.y * gap.y).squareRoot()
                directions.append((gap.x / length, gap.y / length))
                let offset = (x: -gap.y / length * half, y: gap.x / length * half)
                pieces.append(
                    Self.ring([
                        (from.x - offset.x, from.y - offset.y), (to.x - offset.x, to.y - offset.y),
                        (to.x + offset.x, to.y + offset.y), (from.x + offset.x, from.y + offset.y),
                    ])
                )
            }

            for index in vertices.indices {
                if !isClosed, index == 0 || index == count - 1 { continue }
                let vertex = vertices[index]
                let incoming = directions[(index + edges - 1) % edges]
                let outgoing = directions[index % edges]
                let cross = incoming.x * outgoing.y - incoming.y * outgoing.x
                let dot = incoming.x * outgoing.x + incoming.y * outgoing.y
                let turn = Scalar.atan2(cross, dot)
                guard turn != 0 else { continue }
                let side: Scalar = turn > 0 ? -1 : 1
                let before = (x: -incoming.y * side, y: incoming.x * side)
                let after = (x: -outgoing.y * side, y: outgoing.x * side)
                let opening = turn > 0 ? before : after
                let join: Geometry.Path.Stroke.Join = vertex.smooth ? .round : stroke.join
                switch join {
                case .round:
                    pieces.append(
                        Self.sector(
                            center: (vertex.x, vertex.y),
                            radius: half,
                            from: Scalar.atan2(opening.y, opening.x),
                            sweep: abs(turn)
                        )
                    )

                case .bevel, .miter:
                    let one = (x: vertex.x + before.x * half, y: vertex.y + before.y * half)
                    let two = (x: vertex.x + after.x * half, y: vertex.y + after.y * half)
                    var corners = [(x: vertex.x, y: vertex.y), turn > 0 ? one : two]
                    if case .miter(let limit) = join, limit.value * ((1 + dot) / 2).squareRoot() >= 1 {
                        let reach = half / (1 + dot)
                        corners.append(
                            (vertex.x + (before.x + after.x) * reach, vertex.y + (before.y + after.y) * reach)
                        )
                    }
                    corners.append(turn > 0 ? two : one)
                    pieces.append(Self.ring(corners))
                }
            }

            guard !isClosed, let leading = directions.first, let trailing = directions.last else { return }
            switch stroke.cap {
            case .butt:
                break

            case .round:
                pieces.append(
                    Self.sector(
                        center: (first.x, first.y),
                        radius: half,
                        from: Scalar.atan2(leading.x, -leading.y),
                        sweep: Scalar.pi
                    )
                )
                pieces.append(
                    Self.sector(
                        center: (last.x, last.y),
                        radius: half,
                        from: Scalar.atan2(-trailing.x, trailing.y),
                        sweep: Scalar.pi
                    )
                )

            case .square:
                let back = (x: leading.x * half, y: leading.y * half)
                let forth = (x: trailing.x * half, y: trailing.y * half)
                pieces.append(
                    Self.ring([
                        (first.x + back.y, first.y - back.x), (first.x - back.y, first.y + back.x),
                        (first.x - back.y - back.x, first.y + back.x - back.y),
                        (first.x + back.y - back.x, first.y - back.x - back.y),
                    ])
                )
                pieces.append(
                    Self.ring([
                        (last.x + forth.y, last.y - forth.x), (last.x + forth.y + forth.x, last.y - forth.x + forth.y),
                        (last.x - forth.y + forth.x, last.y + forth.x + forth.y), (last.x - forth.y, last.y + forth.x),
                    ])
                )
            }
        }
    }

    extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public func stroked(_ stroke: Stroke, tolerance: Geometry.Length) throws(Error) -> Self {
            let allowance = tolerance.underlying
            guard allowance.isFinite, allowance > 0 else { throw .tolerance }
            let width = stroke.width.underlying
            guard width.isFinite, width >= 0 else { throw .width }
            if case .miter(let limit) = stroke.join {
                guard limit.value.isFinite, limit.value >= 1 else { throw .limit }
            }
            var pieces: [Subpath] = []
            guard width > 0 else { return Self(subpaths: pieces) }
            for subpath in subpaths {
                subpath.outline(stroke, half: width / 2, tolerance: allowance, into: &pieces)
            }
            return Self(subpaths: pieces)
        }
    }

#endif
