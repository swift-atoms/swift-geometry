#if Affine
public import Affine
public import Displacement
public import Point
public import Vector
public import Tagged
public import Scale
public import Angle
public import Trigonometry


public import Linear
@_exported public import Segment

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
    extension Geometry.Line: Codable where Scalar: Codable {}
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
            x: other.x + 2 * dx,
            y: other.y + 2 * dy
        )
    }

    @inlinable
    public func intersections<let N: Int>(with ngon: Geometry.Ngon<N>) -> [Geometry.Point<2>]
    where Scalar: FloatingPoint {
        var result: [Geometry.Point<2>] = []
        let edges = ngon.edges
        for i in 0..<N {

            let seg = edges[i]
            let segLine = Geometry.line(extending: seg)
            guard let pt = intersection(with: segLine) else { continue }

            let displacement = Geometry.vector(of: seg)
            let lenSq = displacement.dx * displacement.dx + displacement.dy * displacement.dy
            guard lenSq > .zero else { continue }

            let vx: Linear<Scalar, Space>.Dx = pt.x - seg.start.x
            let vy: Linear<Scalar, Space>.Dy = pt.y - seg.start.y

            let t: Scale<1, Scalar> = (displacement.dx * vx + displacement.dy * vy) / lenSq
            if t >= 0 && t <= 1 {
                result.append(pt)
            }
        }
        return result
    }
}

extension Geometry.Line {

    public typealias Segment = Segment::Segment<Geometry.Point<2>>
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

extension Geometry where Scalar: AdditiveArithmetic {
    @inlinable
    public static func vector(of segment: Line.Segment) -> Vector<2> {
        .init(from: segment)
    }

    @inlinable
    public static func line(extending segment: Line.Segment) -> Line {
        .init(extending: segment)
    }
}

extension Geometry where Scalar: FloatingPoint {
    @inlinable
    public static func lengthSquared(of segment: Line.Segment) -> Scalar {
        vector(of: segment).lengthSquared
    }

    @inlinable
    public static func length(of segment: Line.Segment) -> Length {
        Length(vector(of: segment).length.underlying)
    }

    @inlinable
    public static func midpoint(of segment: Line.Segment) -> Point<2> {
        point(on: segment, at: 0.5)
    }

    @inlinable
    public static func point(on segment: Line.Segment, at t: Scale<1, Scalar>) -> Point<2> {
        let dx = segment.end.x - segment.start.x
        let dy = segment.end.y - segment.start.y
        return Point(x: segment.start.x + t * dx, y: segment.start.y + t * dy)
    }

    @inlinable
    public static func intersects(_ first: Line.Segment, _ second: Line.Segment) -> Bool {
        intersection(first, second) != nil
    }

    @inlinable
    public static func intersections<let N: Int>(
        of segment: Line.Segment, with ngon: Ngon<N>
    ) -> [Point<2>] {
        var result: [Point<2>] = []
        let edges = ngon.edges
        for i in 0..<N {
            if let point = intersection(segment, edges[i]) {
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
        let d1 = vector(of: segment1)
        let d2 = vector(of: segment2)

        let cross = d1.dx * d2.dy - d1.dy * d2.dx

        guard abs(cross) > .zero else { return nil }

        let dpx: Linear<Scalar, Space>.Dx = segment2.start.x - segment1.start.x
        let dpy: Linear<Scalar, Space>.Dy = segment2.start.y - segment1.start.y

        let t1: Scale<1, Scalar> = (dpx * d2.dy - dpy * d2.dx) / cross
        let t2: Scale<1, Scalar> = (dpx * d1.dy - dpy * d1.dx) / cross

        guard t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1 else { return nil }

        return point(on: segment1, at: t1)
    }

    @inlinable
    public static func distance(from segment: Line.Segment, to point: Point<2>) -> Distance {
        let v = vector(of: segment)

        let lenSq = v.dx * v.dx + v.dy * v.dy

        if lenSq == .zero {
            let dx: Linear<Scalar, Space>.Dx = point.x - segment.start.x
            let dy: Linear<Scalar, Space>.Dy = point.y - segment.start.y

            return sqrt(dx * dx + dy * dy)
        }

        let wx: Linear<Scalar, Space>.Dx = point.x - segment.start.x
        let wy: Linear<Scalar, Space>.Dy = point.y - segment.start.y

        let t: Scale<1, Scalar> = max(0, min(1, (v.dx * wx + v.dy * wy) / lenSq))

        let closest = Self.point(on: segment, at: t)
        let dx: Linear<Scalar, Space>.Dx = point.x - closest.x
        let dy: Linear<Scalar, Space>.Dy = point.y - closest.y

        return sqrt(dx * dx + dy * dy)
    }
}

#endif
