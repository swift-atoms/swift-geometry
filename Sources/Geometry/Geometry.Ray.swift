public import Affine_Geometry
public import Dimension
public import Linear

extension Geometry {

    public struct Ray {

        public var origin: Point<2>

        public var direction: Vector<2>

        @inlinable
        public init(origin: consuming Point<2>, direction: consuming Vector<2>) {
            self.origin = origin
            self.direction = direction
        }
    }
}

extension Geometry.Ray: Sendable where Scalar: Sendable {}
extension Geometry.Ray: Equatable where Scalar: Equatable {}
extension Geometry.Ray: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Ray: Codable where Scalar: Codable {}
#endif

extension Geometry.Ray where Scalar: AdditiveArithmetic {

    @inlinable
    public init(from origin: Geometry.Point<2>, through point: Geometry.Point<2>) {
        self.origin = origin
        self.direction = Geometry.Vector(dx: point.x - origin.x, dy: point.y - origin.y)
    }
}

extension Geometry.Ray where Scalar: FloatingPoint {

    @inlinable
    public init(origin: Geometry.Point<2>, in cardinalDirection: Geometry.Direction) {
        self.origin = origin
        self.direction = cardinalDirection.unitVector
    }
}

extension Geometry.Ray where Scalar: FloatingPoint {

    @inlinable
    public var unitDirection: Geometry.Vector<2>? {
        let normalized = Linear<Scalar, Space>.Vector.normalized(direction)
        guard normalized.length.underlying > 0 else { return nil }
        return normalized
    }

    @inlinable
    public var line: Geometry.Line {
        Geometry.Line(point: origin, direction: direction)
    }
}

extension Geometry.Ray where Scalar: FloatingPoint {

    @inlinable
    public func point(at t: Scale<1, Scalar>) -> Geometry.Point<2> {
        Geometry.point(of: self, at: t)
    }

    @inlinable
    public func contains(_ point: Geometry.Point<2>) -> Bool {
        Geometry.contains(self, point: point)
    }
}

extension Geometry.Ray where Scalar: FloatingPoint {

    @inlinable
    public func distance(to point: Geometry.Point<2>) -> Geometry.Distance {
        Geometry.distance(from: self, to: point)
    }

    @inlinable
    public func closestPoint(to point: Geometry.Point<2>) -> Geometry.Point<2> {

        let lenSq = direction.dx * direction.dx + direction.dy * direction.dy
        guard lenSq > .zero else { return origin }

        let vx = point.x - origin.x
        let vy = point.y - origin.y

        let t: Scale<1, Scalar> = max(0, (direction.dx * vx + direction.dy * vy) / lenSq)

        return self.point(at: t)
    }
}

extension Geometry.Ray where Scalar: FloatingPoint {

    @inlinable
    public func intersection(with other: Self) -> Geometry.Point<2>? {
        let d1x = direction.dx
        let d1y = direction.dy
        let d2x = other.direction.dx
        let d2y = other.direction.dy

        let cross = d1x * d2y - d1y * d2x

        guard abs(cross) > .zero else { return nil }

        let dpx: Linear<Scalar, Space>.Dx = other.origin.x - origin.x
        let dpy: Linear<Scalar, Space>.Dy = other.origin.y - origin.y

        let t1: Scale<1, Scalar> = (dpx * d2y - dpy * d2x) / cross
        let t2: Scale<1, Scalar> = (dpx * d1y - dpy * d1x) / cross

        guard t1 >= 0 && t2 >= 0 else { return nil }

        return point(at: t1)
    }

    @inlinable
    public func intersection(with line: Geometry.Line) -> Geometry.Point<2>? {
        let d1x = direction.dx
        let d1y = direction.dy
        let d2x = line.direction.dx
        let d2y = line.direction.dy

        let cross = d1x * d2y - d1y * d2x

        guard abs(cross) > .zero else { return nil }

        let dpx: Linear<Scalar, Space>.Dx = line.point.x - origin.x
        let dpy: Linear<Scalar, Space>.Dy = line.point.y - origin.y

        let t: Scale<1, Scalar> = (dpx * d2y - dpy * d2x) / cross

        guard t >= 0 else { return nil }

        return point(at: t)
    }

    @inlinable
    public func intersection(with segment: Geometry.Line.Segment) -> Geometry.Point<2>? {
        let d1x = direction.dx
        let d1y = direction.dy
        let d2x = segment.vector.dx
        let d2y = segment.vector.dy

        let cross = d1x * d2y - d1y * d2x

        guard abs(cross) > .zero else { return nil }

        let dpx: Linear<Scalar, Space>.Dx = segment.start.x - origin.x
        let dpy: Linear<Scalar, Space>.Dy = segment.start.y - origin.y

        let t1: Scale<1, Scalar> = (dpx * d2y - dpy * d2x) / cross
        let t2: Scale<1, Scalar> = (dpx * d1y - dpy * d1x) / cross

        guard t1 >= 0 && t2 >= 0 && t2 <= 1 else { return nil }

        return point(at: t1)
    }

    @inlinable
    public func intersection(with circle: Geometry.Circle) -> [Geometry.Point<2>] {

        let lineIntersections = circle.intersection(with: line)

        return lineIntersections.filter { point in
            let vx = point.x - origin.x
            let vy = point.y - origin.y
            let dot = direction.dx * vx + direction.dy * vy
            return dot.underlying >= 0
        }
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

extension Geometry where Scalar: FloatingPoint {

    @inlinable
    public static func point(of ray: Ray, at t: Scale<1, Scalar>) -> Point<2> {

        Point(
            x: ray.origin.x + t * ray.direction.dx,
            y: ray.origin.y + t * ray.direction.dy
        )
    }

    @inlinable
    public static func contains(_ ray: Ray, point: Point<2>) -> Bool {

        let lenSq = ray.direction.dx * ray.direction.dx + ray.direction.dy * ray.direction.dy
        guard lenSq > .zero else { return point == ray.origin }

        let vx: Linear<Scalar, Space>.Dx = point.x - ray.origin.x
        let vy: Linear<Scalar, Space>.Dy = point.y - ray.origin.y

        let t: Scale<1, Scalar> = (ray.direction.dx * vx + ray.direction.dy * vy) / lenSq

        guard t >= 0 else { return false }

        let projected = Self.point(of: ray, at: t)
        let distSq = point.distance.squared(to: projected)

        let tolerance: Linear<Scalar, Space>.Area = Tagged(Scalar.ulpOfOne * 100)
        return distSq < tolerance
    }

    @inlinable
    public static func distance(from ray: Ray, to point: Point<2>) -> Distance {

        let lenSq = ray.direction.dx * ray.direction.dx + ray.direction.dy * ray.direction.dy
        guard lenSq > .zero else {
            return ray.origin.distance(to: point)
        }

        let vx: Linear<Scalar, Space>.Dx = point.x - ray.origin.x
        let vy: Linear<Scalar, Space>.Dy = point.y - ray.origin.y

        let t: Scale<1, Scalar> = max(0, (ray.direction.dx * vx + ray.direction.dy * vy) / lenSq)

        let closest = Self.point(of: ray, at: t)
        return point.distance(to: closest)
    }
}

extension Geometry.Ray {

    @inlinable
    public init<U, E: Swift.Error>(
        _ other: borrowing Geometry<U, Space>.Ray,
        _ transform: (U) throws(E) -> Scalar
    ) throws(E) {
        self.init(
            origin: try Geometry.Point<2>(other.origin, transform),
            direction: try Geometry.Vector<2>(other.direction, transform)
        )
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Ray {
        Geometry<Result, Space>.Ray(
            origin: try origin.map(transform),
            direction: try direction.map(transform)
        )
    }
}

extension Geometry where Scalar: FloatingPoint {

    public enum Direction {
        case right, up, left, down
    }
}

extension Geometry.Direction where Scalar: FloatingPoint {

    @inlinable
    public var unitVector: Geometry.Vector<2> {
        switch self {
        case .right: return Geometry.Vector(dx: .init(_unchecked: 1), dy: .init(_unchecked: 0))
        case .up: return Geometry.Vector(dx: .init(_unchecked: 0), dy: .init(_unchecked: 1))
        case .left: return Geometry.Vector(dx: .init(_unchecked: -1), dy: .init(_unchecked: 0))
        case .down: return Geometry.Vector(dx: .init(_unchecked: 0), dy: .init(_unchecked: -1))
        }
    }
}
