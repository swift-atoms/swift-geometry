public import Affine
public import Dimension
public import Linear
public import Tagged

extension Geometry {

    public struct Line {

        public var point: Point<2>

        public var direction: Vector<2>

        @inlinable
        public init(point: consuming Point<2>, direction: consuming Vector<2>) {
            self.point = point
            self.direction = direction
        }
    }
}

extension Geometry.Line: Sendable where Scalar: Sendable {}
extension Geometry.Line: Equatable where Scalar: Equatable {}
extension Geometry.Line: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Line: Codable where Scalar: Codable {

        private enum CodingKeys: String, CodingKey {
            case point, direction
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            var direction = try container.nestedUnkeyedContainer(forKey: .direction)
            self.init(
                point: try container.decode(Geometry.Point<2>.self, forKey: .point),
                direction: .init(
                    dx: .init(_unchecked: try direction.decode(Scalar.self)),
                    dy: .init(_unchecked: try direction.decode(Scalar.self))
                )
            )
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(point, forKey: .point)
            var directionContainer = container.nestedUnkeyedContainer(forKey: .direction)
            try directionContainer.encode(direction.dx.underlying)
            try directionContainer.encode(direction.dy.underlying)
        }
    }
#endif

extension Geometry.Line where Scalar: AdditiveArithmetic {

    @inlinable
    public init(from: Geometry.Point<2>, to: Geometry.Point<2>) {
        self.point = from
        self.direction = Geometry.Vector(dx: to.x - from.x, dy: to.y - from.y)
    }
}

extension Geometry.Line where Scalar: FloatingPoint {

    @inlinable
    public var normalizedDirection: Geometry.Vector<2> {
        direction.normalized
    }

    @inlinable
    public func point(at t: Scale<1, Scalar>) -> Geometry.Point<2> {
        Geometry.Point(
            x: point.x + t * direction.dx,
            y: point.y + t * direction.dy
        )
    }

    @inlinable
    public func distance(to other: Geometry.Point<2>) -> Geometry.Distance? {
        Geometry.distance(from: self, to: other)
    }

    @inlinable
    public func intersection(with other: Self) -> Geometry.Point<2>? {
        Geometry.intersection(self, other)
    }

    @inlinable
    public func projection(of other: Geometry.Point<2>) -> Geometry.Point<2>? {
        Geometry.projection(of: other, onto: self)
    }

    @inlinable
    public func reflection(of other: Geometry.Point<2>) -> Geometry.Point<2>? {
        guard let projected = projection(of: other) else { return nil }

        let dx = projected.x - other.x
        let dy = projected.y - other.y
        return Geometry.Point(
            x: other.x + Scale(2) * dx,
            y: other.y + Scale(2) * dy
        )
    }

    @inlinable
    public func intersections<let N: Int>(with ngon: Geometry.Ngon<N>) -> [Geometry.Point<2>]
    where Scalar: FloatingPoint {
        var result: [Geometry.Point<2>] = []
        let edges = ngon.edges
        for i in 0..<N {

            let seg = edges[i]
            let segLine = seg.line
            guard let pt = intersection(with: segLine) else { continue }

            let lenSq = seg.vector.dx * seg.vector.dx + seg.vector.dy * seg.vector.dy
            guard lenSq > .zero else { continue }

            let vx: Linear<Scalar, Space>.Dx = pt.x - seg.start.x
            let vy: Linear<Scalar, Space>.Dy = pt.y - seg.start.y

            let t: Scale<1, Scalar> = (seg.vector.dx * vx + seg.vector.dy * vy) / lenSq
            if t.value >= 0 && t.value <= 1 {
                result.append(pt)
            }
        }
        return result
    }
}

extension Geometry.Line {

    public struct Segment {

        public var start: Geometry.Point<2>

        public var end: Geometry.Point<2>

        @inlinable
        public init(start: consuming Geometry.Point<2>, end: consuming Geometry.Point<2>) {
            self.start = start
            self.end = end
        }
    }
}

extension Geometry.Line.Segment: Sendable where Scalar: Sendable {}
extension Geometry.Line.Segment: Equatable where Scalar: Equatable {}
extension Geometry.Line.Segment: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Line.Segment: Codable where Scalar: Codable {}
#endif

extension Geometry.Line.Segment {

    @inlinable
    public var reversed: Self {
        Self(start: end, end: start)
    }
}

extension Linear.Vector where N == 2, Scalar: AdditiveArithmetic {

    @inlinable
    public init(from segment: Geometry<Scalar, Space>.Line.Segment) {
        self.init(dx: segment.end.x - segment.start.x, dy: segment.end.y - segment.start.y)
    }
}

extension Geometry.Line where Scalar: AdditiveArithmetic {

    @inlinable
    public init(extending segment: Segment) {
        self.init(point: segment.start, direction: .init(from: segment))
    }
}

extension Geometry.Line.Segment where Scalar: AdditiveArithmetic {

    @inlinable
    public var vector: Geometry.Vector<2> { .init(from: self) }

    @inlinable
    public var line: Geometry.Line { .init(extending: self) }
}

extension Affine.Continuous.Point where N == 2, Scalar: FloatingPoint {

    @inlinable
    public init(midpointOf segment: Geometry<Scalar, Space>.Line.Segment) {
        let half = Scale<1, Scalar>(Scalar(1) / Scalar(2))
        self.init(
            x: segment.start.x + half * (segment.end.x - segment.start.x),
            y: segment.start.y + half * (segment.end.y - segment.start.y)
        )
    }
}

extension Geometry.Line.Segment where Scalar: FloatingPoint {

    @inlinable
    public var lengthSquared: Scalar {
        vector.lengthSquared
    }

    @inlinable
    public var length: Geometry.Length {
        Geometry.Length(_unchecked: vector.length.underlying)
    }

    @inlinable
    public var midpoint: Geometry.Point<2> { .init(midpointOf: self) }

    @inlinable
    public func point(at t: Scale<1, Scalar>) -> Geometry.Point<2> {
        let dx = end.x - start.x
        let dy = end.y - start.y
        return Geometry.Point(
            x: start.x + t * dx,
            y: start.y + t * dy
        )
    }

    @inlinable
    public func intersection(with other: Self) -> Geometry.Point<2>? {
        Geometry.intersection(self, other)
    }

    @inlinable
    public func intersects(with other: Self) -> Bool {
        intersection(with: other) != nil
    }

    @inlinable
    public func distance(to other: Geometry.Point<2>) -> Geometry.Distance {
        Geometry.distance(from: self, to: other)
    }

    @inlinable
    public func intersections<let N: Int>(with ngon: Geometry.Ngon<N>) -> [Geometry.Point<2>]
    where Scalar: AdditiveArithmetic {
        var result: [Geometry.Point<2>] = []
        let edges = ngon.edges
        (0..<N).forEach { i in
            if let point = intersection(with: edges[i]) {
                result.append(point)
            }
        }
        return result
    }
}

extension Geometry {

    public typealias LineSegment = Line.Segment
}

extension Geometry.Line {

    @inlinable
    public init<U, E: Swift.Error>(
        _ other: borrowing Geometry<U, Space>.Line,
        _ transform: (U) throws(E) -> Scalar
    ) throws(E) {
        self.init(
            point: try Geometry.Point<2>(other.point, transform),
            direction: try Geometry.Vector<2>(other.direction, transform)
        )
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Line {
        Geometry<Result, Space>.Line(
            point: try point.map(transform),
            direction: try direction.map(transform)
        )
    }
}

extension Geometry where Scalar: FloatingPoint {

    @inlinable
    public static func distance(from line: Line, to point: Point<2>) -> Distance? {
        let mag = line.direction.length
        guard mag.underlying != 0 else { return nil }
        let v = Vector(dx: point.x - line.point.x, dy: point.y - line.point.y)
        let cross = line.direction.dx * v.dy - line.direction.dy * v.dx

        return Distance(abs(cross.underlying) / mag.underlying)
    }

    @inlinable
    public static func intersection(_ line1: Line, _ line2: Line) -> Point<2>? {

        let cross =
            line1.direction.dx * line2.direction.dy - line1.direction.dy * line2.direction.dx

        guard abs(cross) > .zero else { return nil }

        let dpx: Linear<Scalar, Space>.Dx = line2.point.x - line1.point.x
        let dpy: Linear<Scalar, Space>.Dy = line2.point.y - line1.point.y

        let t: Scale<1, Scalar> = (dpx * line2.direction.dy - dpy * line2.direction.dx) / cross

        return line1.point(at: t)
    }

    @inlinable
    public static func projection(of point: Point<2>, onto line: Line) -> Point<2>? {

        let lenSq = line.direction.dx * line.direction.dx + line.direction.dy * line.direction.dy
        guard lenSq != .zero else { return nil }

        let vx: Linear<Scalar, Space>.Dx = point.x - line.point.x
        let vy: Linear<Scalar, Space>.Dy = point.y - line.point.y

        let dot = line.direction.dx * vx + line.direction.dy * vy

        let t: Scale<1, Scalar> = dot / lenSq

        return line.point(at: t)
    }
}

extension Geometry where Scalar: FloatingPoint {

    @inlinable
    public static func intersection(_ segment1: Line.Segment, _ segment2: Line.Segment) -> Point<2>? {
        let d1 = segment1.vector
        let d2 = segment2.vector

        let cross = d1.dx * d2.dy - d1.dy * d2.dx

        guard abs(cross) > .zero else { return nil }

        let dpx: Linear<Scalar, Space>.Dx = segment2.start.x - segment1.start.x
        let dpy: Linear<Scalar, Space>.Dy = segment2.start.y - segment1.start.y

        let t1: Scale<1, Scalar> = (dpx * d2.dy - dpy * d2.dx) / cross
        let t2: Scale<1, Scalar> = (dpx * d1.dy - dpy * d1.dx) / cross

        guard t1.value >= 0 && t1.value <= 1 && t2.value >= 0 && t2.value <= 1 else {
            return nil
        }

        return segment1.point(at: t1)
    }

    @inlinable
    public static func distance(from segment: Line.Segment, to point: Point<2>) -> Distance {
        let v = segment.vector

        let lenSq = v.dx * v.dx + v.dy * v.dy

        if lenSq == .zero {
            let dx: Linear<Scalar, Space>.Dx = point.x - segment.start.x
            let dy: Linear<Scalar, Space>.Dy = point.y - segment.start.y

            return sqrt(dx * dx + dy * dy)
        }

        let wx: Linear<Scalar, Space>.Dx = point.x - segment.start.x
        let wy: Linear<Scalar, Space>.Dy = point.y - segment.start.y

        let t: Scale<1, Scalar> = max(
            Scale(0),
            min(Scale(1), (v.dx * wx + v.dy * wy) / lenSq)
        )

        let closest = segment.point(at: t)
        let dx: Linear<Scalar, Space>.Dx = point.x - closest.x
        let dy: Linear<Scalar, Space>.Dy = point.y - closest.y

        return sqrt(dx * dx + dy * dy)
    }
}

extension Geometry.Line.Segment {

    @inlinable
    public init<U, E: Swift.Error>(
        _ other: borrowing Geometry<U, Space>.Line.Segment,
        _ transform: (U) throws(E) -> Scalar
    ) throws(E) {
        self.init(
            start: try Geometry.Point<2>(other.start, transform),
            end: try Geometry.Point<2>(other.end, transform)
        )
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Line.Segment {
        Geometry<Result, Space>.Line.Segment(
            start: try start.map(transform),
            end: try end.map(transform)
        )
    }
}
