public import Affine
public import Dimension
public import Linear
public import Numeric
public import Tagged

extension Geometry {

    public struct Ball<let N: Int> {

        public var center: Point<N>

        public var radius: Radius

        @inlinable
        public init(center: consuming Point<N>, radius: consuming Radius) {
            self.center = center
            self.radius = radius
        }
    }
}

extension Geometry {

    public typealias Circle = Ball<2>

    public typealias Sphere = Ball<3>
}

extension Geometry.Ball: Sendable where Scalar: Sendable {}
extension Geometry.Ball: Equatable where Scalar: Equatable {}
extension Geometry.Ball: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Ball: Codable where Scalar: Codable {

        private enum CodingKeys: String, CodingKey {
            case center, radius
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.init(
                center: try container.decode(Geometry.Point<N>.self, forKey: .center),
                radius: .init(_unchecked: try container.decode(Scalar.self, forKey: .radius))
            )
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(center, forKey: .center)
            try container.encode(radius.underlying, forKey: .radius)
        }
    }
#endif

extension Geometry.Ball where Scalar: AdditiveArithmetic {

    @inlinable
    public init(radius: Geometry.Radius) {
        self.init(center: .zero, radius: radius)
    }
}

extension Geometry.Ball where Scalar: ExpressibleByIntegerLiteral & AdditiveArithmetic {

    @inlinable
    public static var unit: Self {
        Self(center: .zero, radius: .init(_unchecked: 1))
    }
}

extension Geometry.Ball where Scalar: FloatingPoint {

    @inlinable
    public var diameter: Geometry.Magnitude {
        Geometry.Magnitude(.init(_unchecked: radius.underlying * 2))
    }
}

extension Geometry.Ball where N == 2, Scalar: FloatingPoint {

    @inlinable
    public var circumference: Geometry.Circumference {
        Geometry.Circumference(_unchecked: 2 * Scalar.pi * radius.underlying)
    }

    @inlinable
    public var area: Geometry.Area { Geometry.area(of: self) }

    @inlinable
    public var boundingBox: Geometry.Rectangle { Geometry.boundingBox(of: self) }
}

extension Geometry.Ball where N == 3, Scalar: FloatingPoint {

    @inlinable
    public var surfaceArea: Scalar {

        let radiusSq = radius * radius
        return 4 * Scalar.pi * radiusSq.underlying
    }

    @inlinable
    public var volume: Scalar {

        let radiusSq = radius * radius
        let radiusCubed = radiusSq * radius
        return (4 / 3) * Scalar.pi * radiusCubed.underlying
    }
}

extension Geometry.Ball where N == 2, Scalar: FloatingPoint {

    @inlinable
    public init?(_ ellipse: Geometry.Ellipse) {
        let diff: Scalar = ellipse.semiMajor.underlying - ellipse.semiMinor.underlying
        guard abs(diff) < Scalar.ulpOfOne else { return nil }
        self.init(center: ellipse.center, radius: ellipse.semiMajor)
    }
}

extension Geometry.Ball where N == 2, Scalar: FloatingPoint {

    @inlinable
    public func contains(_ point: Geometry.Point<2>) -> Bool {
        Geometry.contains(self, point: point)
    }

    @inlinable
    public func containsInterior(_ point: Geometry.Point<2>) -> Bool {
        center.distance.squared(to: point) < radius * radius
    }

    @inlinable
    public func contains(_ other: Self) -> Bool {
        Geometry.contains(self, other)
    }
}

extension Geometry.Ball where N == 2, Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public func point(at angle: Radian<Scalar>) -> Geometry.Point<2> {

        Geometry.Point(
            x: center.x + radius * angle.cos,
            y: center.y + radius * angle.sin
        )
    }

    @inlinable
    public func tangent(at angle: Radian<Scalar>) -> Geometry.Vector<2> {
        let c = angle.cos.value
        let s = angle.sin.value
        return Geometry.Vector(
            dx: Linear<Scalar, Space>.Dx(_unchecked: -s),
            dy: Linear<Scalar, Space>.Dy(_unchecked: c)
        )
    }

    @inlinable
    public func closestPoint(to point: Geometry.Point<2>) -> Geometry.Point<2> {
        let vx = point.x.underlying - center.x.underlying
        let vy = point.y.underlying - center.y.underlying
        let len = (vx * vx + vy * vy).squareRoot()
        let r = radius.underlying
        guard len > 0 else {
            return Geometry.Point(
                x: Affine.Continuous<Scalar, Space>.X(center.x.underlying + r),
                y: center.y
            )
        }
        let scale = r / len
        return Geometry.Point(
            x: Affine.Continuous<Scalar, Space>.X(center.x.underlying + vx * scale),
            y: Affine.Continuous<Scalar, Space>.Y(center.y.underlying + vy * scale)
        )
    }
}

extension Geometry.Ball where N == 2, Scalar: FloatingPoint {

    @inlinable
    public func intersects(_ other: Self) -> Bool {
        Geometry.intersects(self, other)
    }

    @inlinable
    public func intersection(with line: Geometry.Line) -> [Geometry.Point<2>] {
        Geometry.intersection(self, line)
    }

    @inlinable
    public func intersection(with other: Self) -> [Geometry.Point<2>] {
        Geometry.intersection(self, other)
    }
}

extension Geometry where Scalar: FloatingPoint {

    @inlinable
    public static func area(of circle: Ball<2>) -> Area {
        let radiusSq = circle.radius * circle.radius
        return Area(Scalar.pi * radiusSq.underlying)
    }

    @inlinable
    public static func boundingBox(of circle: Ball<2>) -> Rectangle {
        Rectangle(
            llx: circle.center.x - circle.radius,
            lly: circle.center.y - circle.radius,
            urx: circle.center.x + circle.radius,
            ury: circle.center.y + circle.radius
        )
    }

    @inlinable
    public static func contains(_ circle: Ball<2>, point: Point<2>) -> Bool {
        circle.center.distance.squared(to: point) <= circle.radius * circle.radius
    }

    @inlinable
    public static func contains(_ circle: Ball<2>, _ other: Ball<2>) -> Bool {
        circle.center.distance(to: other.center) + other.radius <= circle.radius
    }

    @inlinable
    public static func intersects(_ circle1: Ball<2>, _ circle2: Ball<2>) -> Bool {
        let dist = circle1.center.distance(to: circle2.center)
        let sumRadii = circle1.radius + circle2.radius
        let diffRadii =
            circle1.radius >= circle2.radius
            ? circle1.radius - circle2.radius : circle2.radius - circle1.radius
        return dist <= sumRadii && dist >= diffRadii
    }

    @inlinable
    public static func intersection(_ circle: Ball<2>, _ line: Line) -> [Point<2>] {
        let fx = line.point.x.underlying - circle.center.x.underlying
        let fy = line.point.y.underlying - circle.center.y.underlying
        let dx = line.direction.dx.underlying
        let dy = line.direction.dy.underlying
        let r = circle.radius.underlying

        let a = dx * dx + dy * dy
        let b = 2 * (fx * dx + fy * dy)
        let c = fx * fx + fy * fy - r * r

        let discriminant = b * b - 4 * a * c

        guard discriminant >= 0 else { return [] }

        if discriminant == 0 {
            let t = -b / (2 * a)
            return [line.point(at: Scale<1, Scalar>(t))]
        }

        let sqrtDisc = discriminant.squareRoot()
        let t1 = (-b - sqrtDisc) / (2 * a)
        let t2 = (-b + sqrtDisc) / (2 * a)
        return [line.point(at: Scale<1, Scalar>(t1)), line.point(at: Scale<1, Scalar>(t2))]
    }

    @inlinable
    public static func intersection(_ circle1: Ball<2>, _ circle2: Ball<2>) -> [Point<2>] {
        let dist = circle1.center.distance(to: circle2.center)
        let sumRadii = circle1.radius + circle2.radius
        let diffRadii =
            circle1.radius >= circle2.radius
            ? circle1.radius - circle2.radius : circle2.radius - circle1.radius

        guard dist <= sumRadii && dist >= diffRadii && dist.underlying > 0 else {
            return []
        }

        let d = dist.underlying
        let r1 = circle1.radius.underlying
        let r2 = circle2.radius.underlying

        let a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
        let hSq = r1 * r1 - a * a

        guard hSq >= 0 else { return [] }
        let h = hSq.squareRoot()

        let cx = circle1.center.x.underlying
        let cy = circle1.center.y.underlying
        let ocx = circle2.center.x.underlying
        let ocy = circle2.center.y.underlying
        let dirX = (ocx - cx) / d
        let dirY = (ocy - cy) / d
        let px = cx + a * dirX
        let py = cy + a * dirY

        if h == 0 {
            return [
                Point(
                    x: Affine.Continuous<Scalar, Space>.X(px),
                    y: Affine.Continuous<Scalar, Space>.Y(py)
                )
            ]
        }

        return [
            Point(
                x: Affine.Continuous<Scalar, Space>.X(px + h * dirY),
                y: Affine.Continuous<Scalar, Space>.Y(py - h * dirX)
            ),
            Point(
                x: Affine.Continuous<Scalar, Space>.X(px - h * dirY),
                y: Affine.Continuous<Scalar, Space>.Y(py + h * dirX)
            ),
        ]
    }
}

extension Geometry.Ball where N == 2, Scalar: FloatingPoint {

    @inlinable
    public func translated(by vector: Geometry.Vector<2>) -> Self {
        Self(center: center + vector, radius: radius)
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>) -> Self {
        Self(center: center, radius: factor * radius)
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>, about point: Geometry.Point<2>) -> Self {
        let f = factor.value
        let px = point.x.underlying
        let py = point.y.underlying
        let cx = center.x.underlying
        let cy = center.y.underlying
        let newCenter = Geometry.Point(
            x: Affine.Continuous<Scalar, Space>.X(px + f * (cx - px)),
            y: Affine.Continuous<Scalar, Space>.Y(py + f * (cy - py))
        )
        return Self(center: newCenter, radius: factor * radius)
    }
}

extension Geometry.Ball {

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Ball<N> {
        Geometry<Result, Space>.Ball(
            center: try center.map(transform),
            radius: try radius.map(transform)
        )
    }
}

extension Geometry.Ball where N == 2, Scalar: BinaryFloatingPoint {

    @inlinable
    public var bezierCurves: [Geometry.Bezier.Segment] {

        let k: Geometry.Radius = radius * Scale(0.5522847498)

        let right = Geometry.Point<2>(x: center.x + radius, y: center.y)
        let bottom = Geometry.Point<2>(x: center.x, y: center.y - radius)
        let left = Geometry.Point<2>(x: center.x - radius, y: center.y)
        let top = Geometry.Point<2>(x: center.x, y: center.y + radius)

        return [
            Geometry.Bezier.Segment(
                start: right,
                control1: Geometry.Point<2>(x: center.x + radius, y: center.y - k),
                control2: Geometry.Point<2>(x: center.x + k, y: center.y - radius),
                end: bottom
            ),
            Geometry.Bezier.Segment(
                start: bottom,
                control1: Geometry.Point<2>(x: center.x - k, y: center.y - radius),
                control2: Geometry.Point<2>(x: center.x - radius, y: center.y - k),
                end: left
            ),
            Geometry.Bezier.Segment(
                start: left,
                control1: Geometry.Point<2>(x: center.x - radius, y: center.y + k),
                control2: Geometry.Point<2>(x: center.x - k, y: center.y + radius),
                end: top
            ),
            Geometry.Bezier.Segment(
                start: top,
                control1: Geometry.Point<2>(x: center.x + k, y: center.y + radius),
                control2: Geometry.Point<2>(x: center.x + radius, y: center.y + k),
                end: right
            ),
        ]
    }

    @inlinable
    public var bezierStartPoint: Geometry.Point<2> {

        Geometry.Point<2>(x: center.x + radius, y: center.y)
    }
}

extension Geometry.Ball where N == 2, Scalar: FloatingPoint {

    @inlinable
    public static func incircle(of triangle: Geometry.Triangle) -> Geometry.Circle? {
        let sides = triangle.sideLengths
        let ab = sides.ab.underlying
        let bc = sides.bc.underlying
        let ca = sides.ca.underlying

        let perimeter = ab + bc + ca
        guard perimeter > 0 else { return nil }

        let v = triangle.vertices
        let ax = v[0].x.underlying
        let ay = v[0].y.underlying
        let bx = v[1].x.underlying
        let by = v[1].y.underlying
        let cx = v[2].x.underlying
        let cy = v[2].y.underlying

        let weightedX1 = bc * ax
        let weightedX2 = ca * bx
        let weightedX3 = ab * cx
        let centerX = (weightedX1 + weightedX2 + weightedX3) / perimeter

        let weightedY1 = bc * ay
        let weightedY2 = ca * by
        let weightedY3 = ab * cy
        let centerY = (weightedY1 + weightedY2 + weightedY3) / perimeter

        let semiPerimeter = perimeter / 2
        let inradius = triangle.area.underlying / semiPerimeter

        return Geometry.Circle(
            center: Geometry.Point(x: Geometry.X(_unchecked: centerX), y: Geometry.Y(_unchecked: centerY)),
            radius: Geometry.Radius(_unchecked: inradius)
        )
    }

    @inlinable
    public static func circumcircle(of triangle: Geometry.Triangle) -> Geometry.Circle? {
        let v = triangle.vertices
        let ax = v[0].x.underlying
        let ay = v[0].y.underlying
        let bx = v[1].x.underlying
        let by = v[1].y.underlying
        let cx = v[2].x.underlying
        let cy = v[2].y.underlying

        let dTerm1 = ax * (by - cy)
        let dTerm2 = bx * (cy - ay)
        let dTerm3 = cx * (ay - by)
        let d = Scalar(2) * (dTerm1 + dTerm2 + dTerm3)
        guard abs(d) > Scalar.ulpOfOne else { return nil }

        let aSq = ax * ax + ay * ay
        let bSq = bx * bx + by * by
        let cSq = cx * cx + cy * cy

        let uxTerm1 = aSq * (by - cy)
        let uxTerm2 = bSq * (cy - ay)
        let uxTerm3 = cSq * (ay - by)
        let ux = (uxTerm1 + uxTerm2 + uxTerm3) / d

        let uyTerm1 = aSq * (cx - bx)
        let uyTerm2 = bSq * (ax - cx)
        let uyTerm3 = cSq * (bx - ax)
        let uy = (uyTerm1 + uyTerm2 + uyTerm3) / d

        let center = Geometry.Point(x: Geometry.X(_unchecked: ux), y: Geometry.Y(_unchecked: uy))
        let radius = center.distance(to: v[0])

        return Geometry.Circle(center: center, radius: radius)
    }
}
