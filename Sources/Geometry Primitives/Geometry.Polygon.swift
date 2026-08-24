public import Affine_Geometry_Primitives
public import Dimension_Primitives
public import Linear_Primitives

extension Geometry {

    public struct Polygon {

        public var vertices: [Point<2>]

        @inlinable
        public init(vertices: consuming [Point<2>]) {
            self.vertices = vertices
        }
    }
}

extension Geometry.Polygon: Sendable where Scalar: Sendable {}
extension Geometry.Polygon: Equatable where Scalar: Equatable {}
extension Geometry.Polygon: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Polygon: Codable where Scalar: Codable {}
#endif

extension Geometry.Polygon {

    @inlinable
    public var vertexCount: Int { vertices.count }

    @inlinable
    public var isValid: Bool { vertices.count >= 3 }
}

extension Geometry.Polygon where Scalar: AdditiveArithmetic {

    @inlinable
    public var edges: [Geometry.Line.Segment] {
        guard vertices.count >= 2 else { return [] }
        var result: [Geometry.Line.Segment] = []
        result.reserveCapacity(vertices.count)
        (0..<vertices.count).forEach { i in
            let next = (i + 1) % vertices.count
            result.append(Geometry.Line.Segment(start: vertices[i], end: vertices[next]))
        }
        return result
    }
}

extension Geometry.Polygon where Scalar: SignedNumeric {

    @inlinable
    public var signedDoubleArea: Linear<Scalar, Space>.Area {
        guard vertices.count >= 3 else { return Tagged(.zero) }

        let zeroX = Geometry.X.zero
        let zeroY = Geometry.Y.zero
        var sum: Linear<Scalar, Space>.Area = Tagged(.zero)

        (0..<vertices.count).forEach { i in
            let j = (i + 1) % vertices.count

            let xi = vertices[i].x - zeroX
            let yi = vertices[i].y - zeroY
            let xj = vertices[j].x - zeroX
            let yj = vertices[j].y - zeroY

            sum = sum + xi * yj - xj * yi
        }
        return sum
    }
}

extension Geometry.Polygon where Scalar: FloatingPoint {

    @inlinable
    public var area: Geometry.Area { Geometry.area(of: self) }

    @inlinable
    public var perimeter: Geometry.Perimeter { Geometry.perimeter(of: self) }
}

extension Geometry.Polygon where Scalar: FloatingPoint & SignedNumeric {

    @inlinable
    public var centroid: Geometry.Point<2>? { Geometry.centroid(of: self) }
}

extension Geometry.Polygon where Scalar: FloatingPoint {

    @inlinable
    public var boundingBox: Geometry.Rectangle? {
        guard let first = vertices.first else { return nil }

        var minX = first.x.underlying
        var maxX = first.x.underlying
        var minY = first.y.underlying
        var maxY = first.y.underlying

        for vertex in vertices.dropFirst() {
            minX = min(minX, vertex.x.underlying)
            maxX = max(maxX, vertex.x.underlying)
            minY = min(minY, vertex.y.underlying)
            maxY = max(maxY, vertex.y.underlying)
        }

        return Geometry.Rectangle(
            llx: Geometry.X(minX),
            lly: Geometry.Y(minY),
            urx: Geometry.X(maxX),
            ury: Geometry.Y(maxY)
        )
    }
}

extension Geometry.Polygon where Scalar: SignedNumeric & Comparable {

    @inlinable
    public var isConvex: Bool {
        guard vertices.count >= 3 else { return true }

        var sign: Linear<Scalar, Space>.Area?
        let zero: Linear<Scalar, Space>.Area = Tagged(.zero)

        for i in 0..<vertices.count {
            let j = (i + 1) % vertices.count
            let k = (i + 2) % vertices.count

            let v1x = vertices[j].x - vertices[i].x
            let v1y = vertices[j].y - vertices[i].y
            let v2x = vertices[k].x - vertices[j].x
            let v2y = vertices[k].y - vertices[j].y

            let cross = v1x * v2y - v1y * v2x

            if let existingSign = sign {
                if cross > zero && existingSign < zero { return false }
                if cross < zero && existingSign > zero { return false }
            } else if cross != zero {
                sign = cross
            }
        }

        return true
    }
}

extension Geometry.Polygon where Scalar: SignedNumeric & Comparable {

    @inlinable
    public var isCounterClockwise: Bool {
        signedDoubleArea > Tagged(.zero)
    }

    @inlinable
    public var isClockwise: Bool {
        signedDoubleArea < Tagged(.zero)
    }

    @inlinable
    public var reversed: Self {
        Self(vertices: vertices.reversed())
    }
}

extension Geometry.Polygon where Scalar: FloatingPoint {

    @inlinable
    public func contains(_ point: Geometry.Point<2>) -> Bool {
        guard vertices.count >= 3 else { return false }

        var inside = false
        var j = vertices.endIndex - 1

        (0..<vertices.count).forEach { i in
            let vi = vertices[i]
            let vj = vertices[j]

            if (vi.y.underlying > point.y.underlying) != (vj.y.underlying > point.y.underlying) {
                let slope =
                    (vj.x.underlying - vi.x.underlying) / (vj.y.underlying - vi.y.underlying)
                let xIntersect = vi.x.underlying + slope * (point.y.underlying - vi.y.underlying)
                if point.x.underlying < xIntersect {
                    inside.toggle()
                }
            }
            j = i
        }

        return inside
    }

    @inlinable
    public func isOnBoundary(_ point: Geometry.Point<2>) -> Bool {
        let threshold = Geometry.Distance(.ulpOfOne * 100)
        for edge in edges {
            if edge.distance(to: point) < threshold {
                return true
            }
        }
        return false
    }
}

extension Geometry.Polygon where Scalar: FloatingPoint {

    @inlinable
    public func translated(by vector: Geometry.Vector<2>) -> Self {
        Self(vertices: vertices.map { $0 + vector })
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>) -> Self? {
        guard let center = centroid else { return nil }
        return scaled(by: factor, about: center)
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>, about point: Geometry.Point<2>) -> Self {

        Self(
            vertices: vertices.map { v in
                Geometry.Point(
                    x: point.x + factor * (v.x - point.x),
                    y: point.y + factor * (v.y - point.y)
                )
            }
        )
    }
}

extension Geometry.Polygon where Scalar: FloatingPoint {

    @inlinable
    public func triangulate() -> [Geometry.Triangle] {
        guard vertices.count >= 3 else { return [] }
        if vertices.count == 3 {
            return [Geometry.Triangle(a: vertices[0], b: vertices[1], c: vertices[2])]
        }

        var remaining = vertices
        var triangles: [Geometry.Triangle] = []
        triangles.reserveCapacity(vertices.count - 2)

        while remaining.count > 3 {
            var earFound = false

            for i in 0..<remaining.count {
                let prev = (i + remaining.count - 1) % remaining.count
                let next = (i + 1) % remaining.count

                let a = remaining[prev]
                let b = remaining[i]
                let c = remaining[next]

                let cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

                guard cross > Tagged(Scalar(0)) else { continue }

                let triangle = Geometry.Triangle(a: a, b: b, c: c)
                var isEar = true

                for j in 0..<remaining.count {
                    if j == prev || j == i || j == next { continue }
                    if triangle.contains(remaining[j]) {
                        isEar = false
                        break
                    }
                }

                if isEar {
                    triangles.append(triangle)
                    remaining.remove(at: i)
                    earFound = true
                    break
                }
            }

            if !earFound {

                break
            }
        }

        if remaining.count == 3 {
            triangles.append(Geometry.Triangle(a: remaining[0], b: remaining[1], c: remaining[2]))
        }

        return triangles
    }
}

extension Geometry where Scalar: FloatingPoint {

    @inlinable
    public static func area(of polygon: Polygon) -> Area {
        let signedArea = signedDoubleArea(of: polygon)

        let absArea = signedArea.underlying < 0 ? -signedArea.underlying : signedArea.underlying
        return Area(absArea / 2)
    }

    @inlinable
    public static func signedDoubleArea(of polygon: Polygon) -> Linear<Scalar, Space>.Area
    where Scalar: SignedNumeric {
        polygon.signedDoubleArea
    }

    @inlinable
    public static func perimeter(of polygon: Polygon) -> Perimeter {
        guard polygon.vertices.count >= 2 else { return .zero }

        var sum: Length = .zero
        (0..<polygon.vertices.count).forEach { i in
            let j = (i + 1) % polygon.vertices.count
            sum += polygon.vertices[i].distance(to: polygon.vertices[j])
        }
        return sum
    }

    @inlinable
    public static func centroid(of polygon: Polygon) -> Point<2>? where Scalar: SignedNumeric {
        guard polygon.vertices.count >= 3 else { return nil }

        let a = signedDoubleArea(of: polygon).underlying
        guard abs(a) > .ulpOfOne else { return nil }

        var cx: Scalar = .zero
        var cy: Scalar = .zero

        let zeroX = X.zero
        let zeroY = Y.zero

        (0..<polygon.vertices.count).forEach { i in
            let j = (i + 1) % polygon.vertices.count

            let xi = polygon.vertices[i].x - zeroX
            let yi = polygon.vertices[i].y - zeroY
            let xj = polygon.vertices[j].x - zeroX
            let yj = polygon.vertices[j].y - zeroY

            let cross = (xi * yj - xj * yi).underlying

            cx += (xi.underlying + xj.underlying) * cross
            cy += (yi.underlying + yj.underlying) * cross
        }

        let factor: Scalar = 1 / (3 * a)
        return Point(x: X(cx * factor), y: Y(cy * factor))
    }
}

extension Geometry.Polygon {

    @inlinable
    public init<U, E: Swift.Error>(
        _ other: borrowing Geometry<U, Space>.Polygon,
        _ transform: (U) throws(E) -> Scalar
    ) throws(E) {
        var result: [Geometry.Point<2>] = []
        result.reserveCapacity(other.vertices.count)
        for vertex in other.vertices {
            result.append(try Geometry.Point<2>(vertex, transform))
        }
        self.init(vertices: result)
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Polygon {
        var result: [Geometry<Result, Space>.Point<2>] = []
        result.reserveCapacity(vertices.count)
        for vertex in vertices {
            result.append(try vertex.map(transform))
        }
        return Geometry<Result, Space>.Polygon(vertices: result)
    }
}
