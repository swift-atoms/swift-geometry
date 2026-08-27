import Affine
import Dimension
import Affine_Test_Support
import Linear
import Testing

@testable import Geometry

private typealias Geo = Geometry<Double, Void>
private typealias GeoFloat = Geometry<Float, Void>
private typealias X = Geo.X
private typealias Y = Geo.Y
private typealias Dx = Linear<Double, Void>.Dx
private typealias Dy = Linear<Double, Void>.Dy
private typealias Length = Linear<Double, Void>.Magnitude

private func isApprox(_ a: X, _ b: X, tol: Double = 1e-4) -> Bool {
    let diff = a - b
    let tolerance = Dx(tol)
    return diff > -tolerance && diff < tolerance
}

private func isApprox(_ a: Y, _ b: Y, tol: Double = 1e-4) -> Bool {
    let diff = a - b
    let tolerance = Dy(tol)
    return diff > -tolerance && diff < tolerance
}

private func isApprox(_ a: GeoFloat.X, _ b: GeoFloat.X, tol: Float = 1e-4) -> Bool {
    let diff = a - b
    let tolerance = Linear<Float, Void>.Dx(tol)
    return diff > -tolerance && diff < tolerance
}

private func isApprox(_ a: GeoFloat.Y, _ b: GeoFloat.Y, tol: Float = 1e-4) -> Bool {
    let diff = a - b
    let tolerance = Linear<Float, Void>.Dy(tol)
    return diff > -tolerance && diff < tolerance
}

private func isApprox(_ a: Length, _ b: Length, tol: Double = 1e-10) -> Bool {
    let diff = a - b
    let tolerance = Length(tol)
    return diff > -tolerance && diff < tolerance
}

struct TestUnit: AdditiveArithmetic, Comparable, Codable, Hashable, ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral
{
    let value: Double

    init(_ value: Double) {
        self.value = value
    }

    init(integerLiteral value: Int) {
        self.value = Double(value)
    }

    init(floatLiteral value: Double) {
        self.value = value
    }
}

extension TestUnit {
    static var zero: Self { Self(0) }

    static func + (lhs: Self, rhs: Self) -> Self {
        Self(lhs.value + rhs.value)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        Self(lhs.value - rhs.value)
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}

@Suite
struct `Geometry Unit Tests` {
    @Test
    func `Double conforms to Geometry Unit`() {
        let point: Geometry<Double, Void>.Point<2> = .init(x: 10, y: 20)
        #expect(point.x == 10)
    }

    @Test
    func `Custom type conforms to Geometry Unit`() {
        let point: Geometry<TestUnit, Void>.Point<2> = .init(x: 10, y: 20)
        #expect(point.x == 10)
    }
}

@Suite
struct `Point Tests` {
    @Test
    func `Creates point with coordinates`() {
        let point: Geometry<TestUnit, Void>.Point<2> = .init(x: 10, y: 20)
        #expect(point.x == 10)
        #expect(point.y == 20)
    }

    @Test
    func `Zero point`() {
        let zero: Geometry<TestUnit, Void>.Point<2> = .zero
        #expect(zero.x == 0)
        #expect(zero.y == 0)
    }

    @Test
    func `Point subtraction returns Vector`() {

        let a: Geometry<TestUnit, Void>.Point<2> = .init(x: 10, y: 20)
        let b: Geometry<TestUnit, Void>.Point<2> = .init(x: 5, y: 15)
        let displacement: Geometry<TestUnit, Void>.Vector<2> = a - b
        #expect(displacement.dx == 5)
        #expect(displacement.dy == 5)
    }

    @Test
    func `Double point translation`() {
        let point: Geometry<Double, Void>.Point<2> = .init(x: 10, y: 20)
        let moved = point.translated(dx: 5, dy: 10)
        #expect(moved.x == 15)
        #expect(moved.y == 30)
    }

    @Test
    func `Double point distance`() {
        let a: Geometry<Double, Void>.Point<2> = .init(x: 0, y: 0)
        let b: Geometry<Double, Void>.Point<2> = .init(x: 3, y: 4)
        #expect(a.distance(to: b) == 5)
    }

    @Test
    func `Point plus vector`() {
        let point: Geometry<Double, Void>.Point<2> = .init(x: 10, y: 20)
        let vector: Geo.Vector<2> = .init(dx: 5, dy: 10)
        let result = point + vector
        #expect(result.x == 15)
        #expect(result.y == 30)
    }
}

@Suite
struct `Vector Tests` {
    @Test
    func `Creates vector`() {
        let v: Geo.Vector<2> = .init(dx: 3, dy: 4)
        #expect(v.dx == 3)
        #expect(v.dy == 4)
    }

    @Test
    func `Vector length`() {
        let v: Geo.Vector<2> = .init(dx: 3, dy: 4)
        #expect(v.length == 5)
        #expect(v.lengthSquared == 25)
    }

    @Test
    func `Vector normalization`() {
        let v: Geo.Vector<2> = .init(dx: 3, dy: 4)
        let n = v.normalized
        #expect(abs(n.length - 1.0) < 0.0001)
    }

    @Test
    func `Vector dot product`() {
        let a: Geo.Vector<2> = .init(dx: 1, dy: 0)
        let b: Geo.Vector<2> = .init(dx: 0, dy: 1)
        #expect(a.dot(b) == 0)
    }

    @Test
    func `Vector cross product`() {
        let a: Geo.Vector<2> = .init(dx: 1, dy: 0)
        let b: Geo.Vector<2> = .init(dx: 0, dy: 1)
        #expect(a.cross(b) == 1)
    }

    @Test
    func `Vector arithmetic`() {
        let a: Geo.Vector<2> = .init(dx: 10, dy: 20)
        let b: Geo.Vector<2> = .init(dx: 5, dy: 10)

        #expect((a + b).dx == 15)
        #expect((a - b).dx == 5)
        #expect((a * Scale(2.0)).dx == 20)
        #expect((a / Scale(2.0)).dx == 5)
    }
}

@Suite
struct `Size Tests` {
    @Test
    func `Creates size with dimensions`() {
        let size: Geometry<TestUnit, Void>.Size<2> = .init(width: 100, height: 200)
        #expect(size.width == 100)
        #expect(size.height == 200)
    }

    @Test
    func `Zero size`() {
        let zero: Geometry<TestUnit, Void>.Size<2> = .zero
        #expect(zero.width == 0)
        #expect(zero.height == 0)
    }
}

@Suite
struct `Rectangle Tests` {
    @Test
    func `Creates rectangle from corners`() {
        let rect: Geometry<Double, Void>.Rectangle = .init(llx: 10, lly: 20, urx: 110, ury: 220)
        #expect(rect.llx == 10)
        #expect(rect.lly == 20)
        #expect(rect.urx == 110)
        #expect(rect.ury == 220)
    }

    @Test
    func `Creates rectangle from origin and size`() {
        let rect: Geometry<Double, Void>.Rectangle = .init(x: 10, y: 20, width: 100, height: 200)
        #expect(rect.llx == 10)
        #expect(rect.lly == 20)
        #expect(rect.width == 100)
        #expect(rect.height == 200)
    }

    @Test
    func `Rectangle contains point`() {
        let rect: Geometry<Double, Void>.Rectangle = .init(x: 0, y: 0, width: 100, height: 100)
        let inside: Geometry<Double, Void>.Point<2> = .init(x: 50, y: 50)
        let outside: Geometry<Double, Void>.Point<2> = .init(x: 150, y: 150)

        #expect(rect.contains(inside))
        #expect(!rect.contains(outside))
    }

    @Test
    func `Rectangle intersection`() {
        let a: Geometry<Double, Void>.Rectangle = .init(x: 0, y: 0, width: 100, height: 100)
        let b: Geometry<Double, Void>.Rectangle = .init(x: 50, y: 50, width: 100, height: 100)

        #expect(a.intersects(b))

        let intersection = a.intersection(b)!
        #expect(intersection.llx == 50)
        #expect(intersection.lly == 50)
        #expect(intersection.urx == 100)
        #expect(intersection.ury == 100)
    }

    @Test
    func `Rectangle union`() {
        let a: Geometry<Double, Void>.Rectangle = .init(x: 0, y: 0, width: 50, height: 50)
        let b: Geometry<Double, Void>.Rectangle = .init(x: 50, y: 50, width: 50, height: 50)

        let union = a.union(b)
        #expect(union.minX == 0)
        #expect(union.minY == 0)
        #expect(union.maxX == 100)
        #expect(union.maxY == 100)
    }

    @Test
    func `Rectangle inset`() {
        let rect: Geometry<Double, Void>.Rectangle = .init(x: 0, y: 0, width: 100, height: 100)
        let inset = rect.insetBy(dx: 10, dy: 20)

        #expect(inset.llx == 10)
        #expect(inset.lly == 20)
        #expect(inset.urx == 90)
        #expect(inset.ury == 80)
    }

    @Test
    func `Rectangle center`() {
        let rect: Geometry<Double, Void>.Rectangle = .init(x: 0, y: 0, width: 100, height: 100)
        #expect(rect.midX == 50)
        #expect(rect.midY == 50)
        #expect(rect.center.x == 50)
        #expect(rect.center.y == 50)
    }

    @Test
    func `Rectangle corners`() {
        let rect: Geometry<Double, Void>.Rectangle = .init(x: 10, y: 20, width: 100, height: 200)

        let ll = rect.corner(.bottomLeft)
        #expect(ll.x == 10)
        #expect(ll.y == 20)

        let ur = rect.corner(.topRight)
        #expect(ur.x == 110)
        #expect(ur.y == 220)
    }
}

@Suite
struct `Radian Tests` {
    @Test
    func `Radian zero`() {
        let zero: Radian<Double> = .zero
        #expect(zero == 0)
    }

    @Test
    func `Radian arithmetic`() {
        let a: Radian<Double> = .init(_unchecked: 1.0)
        let b: Radian<Double> = .init(_unchecked: 2.0)
        let sum = a + b
        #expect(sum == 3.0)
    }

    @Test
    func `Radian comparable`() {
        let a: Radian<Double> = .init(_unchecked: 1.0)
        let b: Radian<Double> = .init(_unchecked: 2.0)
        #expect(a < b)
    }
}

@Suite
struct `Degree Tests` {
    @Test
    func `Degree zero`() {
        let zero: Degree<Double> = .zero
        #expect(zero == 0)
    }

    @Test
    func `Degree arithmetic`() {
        let a: Degree<Double> = .init(45)
        let b: Degree<Double> = .init(45)
        let sum = a + b
        #expect(sum == 90)
    }

    @Test
    func `Degree comparable`() {
        let a: Degree<Double> = .init(45)
        let b: Degree<Double> = .init(90)
        #expect(a < b)
    }

    @Test
    func `Degree literal`() {
        let deg: Degree<Double> = 90.0
        #expect(deg == 90)
    }
}

@Suite
struct `Transform Tests` {
    @Test
    func `Identity transform`() {
        let transform: Geometry<Double, Void>.Transform = .identity
        let point: Geometry<Double, Void>.Point<2> = .init(x: 10, y: 20)
        let result = transform.apply(to: point)

        #expect(result.x == 10)
        #expect(result.y == 20)
    }

    @Test
    func `Translation transform`() {
        let transform: Geometry<Double, Void>.Transform = .translation(dx: 100, dy: 50)
        let point: Geometry<Double, Void>.Point<2> = .init(x: 10, y: 20)
        let result = transform.apply(to: point)

        #expect(result.x == 110)
        #expect(result.y == 70)
    }

    @Test
    func `Scale transform`() {
        let transform: Geometry<Double, Void>.Transform = .scale(2)
        let point: Geometry<Double, Void>.Point<2> = .init(x: 10, y: 20)
        let result = transform.apply(to: point)

        #expect(result.x == 20)
        #expect(result.y == 40)
    }

    @Test
    func `Rotation transform`() {

        let transform: Geometry<Double, Void>.Transform = .rotation(.pi.half)
        let point: Geometry<Double, Void>.Point<2> = .init(x: 1, y: 0)
        let result = transform.apply(to: point)

        #expect(isApprox(result.x, X(0)))
        #expect(isApprox(result.y, Y(1)))
    }

    @Test
    func `Transform concatenation`() {
        let translate: Geometry<Double, Void>.Transform = .translation(dx: 10, dy: 0)
        let scale: Geometry<Double, Void>.Transform = .scale(2)

        let combined = translate.concatenating(scale)

        let point: Geometry<Double, Void>.Point<2> = .init(x: 5, y: 5)
        let result = combined.apply(to: point)

        #expect(result.x == 20)
        #expect(result.y == 10)
    }

    @Test
    func `Transform inversion`() {
        let transform: Geometry<Double, Void>.Transform = .translation(dx: 100, dy: 50)
        let inverse = transform.inverted!

        let point: Geometry<Double, Void>.Point<2> = .init(x: 110, y: 70)
        let result = inverse.apply(to: point)

        #expect(isApprox(result.x, X(10)))
        #expect(isApprox(result.y, Y(20)))
    }
}

@Suite
struct `Line Segment Tests` {
    @Test
    func `Line segment length`() {
        let segment: Geometry<Double, Void>.LineSegment = .init(
            start: .init(x: 0, y: 0),
            end: .init(x: 3, y: 4)
        )
        #expect(segment.length == 5)
    }

    @Test
    func `Line segment midpoint`() {
        let segment: Geometry<Double, Void>.LineSegment = .init(
            start: .init(x: 0, y: 0),
            end: .init(x: 10, y: 10)
        )
        #expect(segment.midpoint.x == 5)
        #expect(segment.midpoint.y == 5)
    }

    @Test
    func `Line segment point at parameter`() {
        let segment: Geometry<Double, Void>.LineSegment = .init(
            start: .init(x: 0, y: 0),
            end: .init(x: 10, y: 10)
        )

        let quarter = segment.point(at: 0.25)
        #expect(quarter.x == 2.5)
        #expect(quarter.y == 2.5)
    }

    @Test
    func `Line segment vector`() {
        let segment: Geometry<Double, Void>.LineSegment = .init(
            start: .init(x: 10, y: 20),
            end: .init(x: 30, y: 50)
        )
        #expect(segment.vector.dx == 20)
        #expect(segment.vector.dy == 30)
    }
}

@Suite
struct `Line Tests` {
    @Test
    func `Line from point and direction`() {
        let line: Geometry<Double, Void>.Line = .init(
            point: .init(x: 0, y: 0),
            direction: .init(dx: 1, dy: 1)
        )
        #expect(line.point.x == 0)
        #expect(line.point.y == 0)
        #expect(line.direction.dx == 1)
        #expect(line.direction.dy == 1)
    }

    @Test
    func `Line from two points`() {
        let line: Geometry<Double, Void>.Line = .init(
            from: .init(x: 0, y: 0),
            to: .init(x: 10, y: 20)
        )
        #expect(line.point.x == 0)
        #expect(line.point.y == 0)
        #expect(line.direction.dx == 10)
        #expect(line.direction.dy == 20)
    }

    @Test
    func `Line point at parameter`() {
        let line: Geometry<Double, Void>.Line = .init(
            point: .init(x: 0, y: 0),
            direction: .init(dx: 10, dy: 10)
        )
        let p = line.point(at: 0.5)
        #expect(p.x == 5)
        #expect(p.y == 5)
    }

    @Test
    func `Line distance to point`() {

        let line: Geometry<Double, Void>.Line = .init(
            point: .init(x: 0, y: 0),
            direction: .init(dx: 1, dy: 0)
        )

        let point: Geometry<Double, Void>.Point<2> = .init(x: 5, y: 3)
        #expect(line.distance(to: point) == 3)

        let degenerateLine: Geometry<Double, Void>.Line = .init(
            point: .init(x: 0, y: 0),
            direction: .init(dx: 0, dy: 0)
        )
        #expect(degenerateLine.distance(to: point) == nil)
    }

    @Test
    func `Line Segment via nested type`() {

        let segment: Geometry<Double, Void>.Line.Segment = .init(
            start: .init(x: 0, y: 0),
            end: .init(x: 3, y: 4)
        )
        #expect(segment.length == 5)
    }

    @Test
    func `Segment to Line conversion`() {
        let segment: Geometry<Double, Void>.Line.Segment = .init(
            start: .init(x: 10, y: 20),
            end: .init(x: 30, y: 50)
        )
        let line = segment.line
        #expect(line.point.x == 10)
        #expect(line.point.y == 20)
        #expect(line.direction.dx == 20)
        #expect(line.direction.dy == 30)
    }
}

@Suite
struct `Insets Tests` {
    @Test
    func `Creates edge insets`() {
        let insets: Geometry<TestUnit, Void>.Insets = .init(
            top: 10,
            leading: 20,
            bottom: 30,
            trailing: 40
        )
        #expect(insets.top == 10)
        #expect(insets.leading == 20)
        #expect(insets.bottom == 30)
        #expect(insets.trailing == 40)
    }

    @Test
    func `Creates uniform edge insets`() {
        let insets: Geometry<TestUnit, Void>.Insets = .init(all: 10)
        #expect(insets.top == 10)
        #expect(insets.leading == 10)
        #expect(insets.bottom == 10)
        #expect(insets.trailing == 10)
    }

    @Test
    func `Zero edge insets`() {
        let zero: Geometry<TestUnit, Void>.Insets = .zero
        #expect(zero.top == 0)
        #expect(zero.leading == 0)
        #expect(zero.bottom == 0)
        #expect(zero.trailing == 0)
    }
}

@Suite
struct `Dimension Tests` {
    @Test
    func `Width comparison`() {
        let a: Geometry<TestUnit, Void>.Width = .init(10)
        let b: Geometry<TestUnit, Void>.Width = .init(20)
        #expect(a < b)
    }

    @Test
    func `Height addition`() {
        let a: Geometry<TestUnit, Void>.Height = .init(10)
        let b: Geometry<TestUnit, Void>.Height = .init(20)
        let sum = a + b
        #expect(sum == 30)
    }

    @Test
    func `Length zero`() {
        let zero: Geometry<TestUnit, Void>.Length = .zero
        #expect(zero == 0)
    }

    @Test
    func `Width literals`() {
        let w: Geometry<Double, Void>.Width = 100.0
        #expect(w == 100)

        let wInt: Geometry<Double, Void>.Width = 50
        #expect(wInt == 50)
    }

    @Test
    func `Height negation`() {
        let h: Geometry<Double, Void>.Height = .init(10)
        let neg = -h
        #expect(neg == -10)
    }

    @Test
    func `Length multiplication and division`() {
        let len: Geometry<Double, Void>.Length = .init(10)
        let scaled: Geometry<Double, Void>.Length = len * 2.0
        #expect(isApprox(scaled, Length(20)))
        let scaled2: Geometry<Double, Void>.Length = 2.0 * len
        #expect(isApprox(scaled2, Length(20)))
        let divided: Geometry<Double, Void>.Length = len / 2.0
        #expect(isApprox(divided, Length(5)))
    }

    @Test
    func `X negation`() {
        let x: Geometry<Double, Void>.X = .init(10)
        #expect((-x) == -10)

    }

    @Test
    func `Y negation`() {
        let y: Geometry<Double, Void>.Y = .init(10)
        #expect((-y) == -10)

    }
}

@Suite
struct `Transform Generic Tests` {
    @Test
    func `Float Transform`() {
        let transform: Geometry<Float, Void>.Transform = .identity
        let point: Geometry<Float, Void>.Point<2> = .init(x: 10, y: 20)
        let result = transform.apply(to: point)
        let expectedX: GeoFloat.X = 10
        let expectedY: GeoFloat.Y = 20
        #expect(result.x == expectedX)
        #expect(result.y == expectedY)
    }

    @Test
    func `Float rotation`() {
        let transform: Geometry<Float, Void>.Transform = .rotation(.pi.half)
        let point: Geometry<Float, Void>.Point<2> = .init(x: 1, y: 0)
        let result = transform.apply(to: point)
        #expect(isApprox(result.x, GeoFloat.X(0)))
        #expect(isApprox(result.y, GeoFloat.Y(1)))
    }
}

@Suite
struct `Linear Transform Tests` {
    typealias Matrix2x2 = Linear<Double, Void>.Matrix<2, 2>

    @Test
    func `Linear identity`() {
        let identity = Matrix2x2.identity
        #expect(identity.a == 1)
        #expect(identity.b == 0)
        #expect(identity.c == 0)
        #expect(identity.d == 1)
    }

    @Test
    func `Linear concatenation`() {
        let scale = Matrix2x2.scale(2)
        let rotation = Matrix2x2.rotation(.pi.half)
        let combined = rotation * scale

        #expect(abs(combined.a) < 1e-10)
        #expect(abs(combined.b + 2) < 1e-10)
        #expect(abs(combined.c - 2) < 1e-10)
        #expect(abs(combined.d) < 1e-10)
    }

    @Test
    func `Linear determinant`() {
        let identity = Matrix2x2.identity
        #expect(identity.determinant == 1)

        let scale = Matrix2x2.scale(x: 2, y: 3)
        #expect(scale.determinant == 6)
    }

    @Test
    func `Linear inversion`() {
        let scale = Matrix2x2.scale(x: 2, y: 4)
        let inverted = scale.inverse!
        #expect(inverted.a == 0.5)
        #expect(inverted.d == 0.25)

        let singular = Matrix2x2(a: 1, b: 1, c: 1, d: 1)
        #expect(singular.inverse == nil)
    }
}

@Suite
struct `Scale Transform Tests` {
    @Test
    func `Scale identity`() {
        let identity = Scale<2, Double>.identity
        #expect(identity.x == 1)
        #expect(identity.y == 1)
    }

    @Test
    func `Scale uniform`() {
        let uniform = Scale<2, Double>.uniform(3)
        #expect(uniform.x == 3)
        #expect(uniform.y == 3)
    }

    @Test
    func `Scale composition`() {
        let a = Scale<2, Double>(x: 2, y: 3)
        let b = Scale<2, Double>(x: 4, y: 5)
        let combined = a.concatenating(b)
        #expect(combined.x == 8)
        #expect(combined.y == 15)
    }

    @Test
    func `Scale inversion`() {
        let scale = Scale<2, Double>(x: 2, y: 4)
        let inverted = scale.inverted
        #expect(inverted.x == 0.5)
        #expect(inverted.y == 0.25)
    }
}
