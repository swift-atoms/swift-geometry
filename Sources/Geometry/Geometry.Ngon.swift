public import Affine
public import Dimension
public import Linear
import Numeric
public import Numeric_Standard_Library_Integration
public import Tagged

extension Geometry {

    public struct Ngon<let N: Int> {

        public var vertices: InlineArray<N, Point<2>>

        @inlinable
        public init(_ vertices: consuming InlineArray<N, Point<2>>) {
            self.vertices = vertices
        }
    }
}

extension Geometry.Ngon: Sendable where Scalar: Sendable {}

extension Geometry.Ngon: Equatable where Scalar: Equatable {

    @inlinable
    public static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        for i in 0..<N {
            if lhs.vertices[i] != rhs.vertices[i] {
                return false
            }
        }
        return true
    }
}

extension Geometry.Ngon: Hashable where Scalar: Hashable {

    @inlinable
    public func hash(into hasher: inout Hasher) {
        (0..<N).forEach { i in
            hasher.combine(vertices[i])
        }
    }
}

#if !hasFeature(Embedded)
    extension Geometry.Ngon: Codable where Scalar: Codable {

        public init(from decoder: any Decoder) throws {
            var container = try decoder.unkeyedContainer()
            let first = try container.decode(Geometry.Point<2>.self)
            var verts = InlineArray<N, Geometry.Point<2>>(repeating: first)
            for i in 1..<N {
                verts[i] = try container.decode(Geometry.Point<2>.self)
            }
            self.vertices = verts
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.unkeyedContainer()
            for i in 0..<N {
                try container.encode(vertices[i])
            }
        }
    }
#endif

extension Geometry {

    public typealias Quadrilateral = Ngon<4>

    public typealias Pentagon = Ngon<5>

    public typealias Hexagon = Ngon<6>
}

extension Geometry.Ngon {

    @inlinable
    public subscript(index: Int) -> Geometry.Point<2> {
        get { vertices[index] }
        set { vertices[index] = newValue }
    }
}

extension Geometry.Ngon {

    @inlinable
    public init?(vertices array: [Geometry.Point<2>]) {
        guard array.count == N, let first = array.first else { return nil }
        var verts = InlineArray<N, Geometry.Point<2>>(repeating: first)
        (1..<N).forEach { i in
            verts[i] = array[i]
        }
        self.init(verts)
    }
}

extension Geometry.Ngon {

    @inlinable
    public var vertexArray: [Geometry.Point<2>] {
        var result: [Geometry.Point<2>] = []
        result.reserveCapacity(N)
        (0..<N).forEach { i in
            result.append(vertices[i])
        }
        return result
    }
}

extension Geometry {

    public struct Edges<let N: Int> {

        public var segments: InlineArray<N, Line.Segment>

        @inlinable
        public init(_ segments: InlineArray<N, Line.Segment>) {
            self.segments = segments
        }
    }
}

extension Geometry.Edges: Sendable where Scalar: Sendable {}

extension Geometry.Edges: Equatable where Scalar: Equatable {

    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        for i in 0..<N {
            if lhs.segments[i] != rhs.segments[i] {
                return false
            }
        }
        return true
    }
}

extension Geometry.Edges: Hashable where Scalar: Hashable {

    @inlinable
    public func hash(into hasher: inout Hasher) {
        (0..<N).forEach { i in
            hasher.combine(segments[i])
        }
    }
}

extension Geometry.Edges where N == 3 {

    @inlinable
    public var ab: Geometry.Line.Segment {
        get { segments[0] }
        set { segments[0] = newValue }
    }

    @inlinable
    public var bc: Geometry.Line.Segment {
        get { segments[1] }
        set { segments[1] = newValue }
    }

    @inlinable
    public var ca: Geometry.Line.Segment {
        get { segments[2] }
        set { segments[2] = newValue }
    }
}

extension Geometry.Edges where N == 4 {

    @inlinable
    public var ab: Geometry.Line.Segment {
        get { segments[0] }
        set { segments[0] = newValue }
    }

    @inlinable
    public var bc: Geometry.Line.Segment {
        get { segments[1] }
        set { segments[1] = newValue }
    }

    @inlinable
    public var cd: Geometry.Line.Segment {
        get { segments[2] }
        set { segments[2] = newValue }
    }

    @inlinable
    public var da: Geometry.Line.Segment {
        get { segments[3] }
        set { segments[3] = newValue }
    }
}

extension Geometry.Ngon where Scalar: AdditiveArithmetic {

    @inlinable
    public var edges: Geometry.Edges<N> {
        let first = Geometry.Line.Segment(start: vertices[0], end: vertices[1 % N])
        var result = InlineArray<N, Geometry.Line.Segment>(repeating: first)
        (0..<N).forEach { i in
            let next = (i + 1) % N
            result[i] = Geometry.Line.Segment(start: vertices[i], end: vertices[next])
        }
        return Geometry.Edges(result)
    }
}

extension Geometry.Ngon where Scalar: SignedNumeric {

    @inlinable
    public var signedDoubleArea: Linear<Scalar, Space>.Area {

        let zeroX = Geometry.X.zero
        let zeroY = Geometry.Y.zero
        var sum: Linear<Scalar, Space>.Area = .zero
        (0..<N).forEach { i in
            let j = (i + 1) % N

            let xi = vertices[i].x - zeroX
            let yi = vertices[i].y - zeroY
            let xj = vertices[j].x - zeroX
            let yj = vertices[j].y - zeroY

            sum = sum + xi * yj - xj * yi
        }
        return sum
    }
}

extension Geometry.Ngon where Scalar: FloatingPoint {

    @inlinable
    public var signedArea: Linear<Scalar, Space>.Area {
        signedDoubleArea / Scale(2)
    }

    @inlinable
    public var area: Geometry.Area { Geometry.area(of: self) }

    @inlinable
    public var perimeter: Geometry.Perimeter { Geometry.perimeter(of: self) }
}

extension Geometry.Ngon where Scalar: FloatingPoint & SignedNumeric {

    @inlinable
    public var centroid: Geometry.Point<2>? { Geometry.centroid(of: self) }
}

extension Geometry.Ngon where Scalar: FloatingPoint {

    @inlinable
    public var boundingBox: Geometry.Rectangle {
        var minX = vertices[0].x
        var maxX = vertices[0].x
        var minY = vertices[0].y
        var maxY = vertices[0].y

        (1..<N).forEach { i in
            minX = min(minX, vertices[i].x)
            maxX = max(maxX, vertices[i].x)
            minY = min(minY, vertices[i].y)
            maxY = max(maxY, vertices[i].y)
        }

        return Geometry.Rectangle(
            llx: minX,
            lly: minY,
            urx: maxX,
            ury: maxY
        )
    }
}

extension Geometry.Ngon where Scalar: SignedNumeric & Comparable {

    @inlinable
    public var isConvex: Bool {

        var sign: Linear<Scalar, Space>.Area?
        let zero: Linear<Scalar, Space>.Area = .zero

        for i in 0..<N {
            let j = (i + 1) % N
            let k = (i + 2) % N

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

extension Geometry.Ngon where Scalar: SignedNumeric & Comparable {

    @inlinable
    public var isCounterClockwise: Bool {
        signedDoubleArea > .zero
    }

    @inlinable
    public var isClockwise: Bool {
        signedDoubleArea < .zero
    }

    @inlinable
    public var reversed: Self {
        var newVerts = vertices
        (0..<(N / 2)).forEach { i in
            let j = N - 1 - i
            let temp = newVerts[i]
            newVerts[i] = newVerts[j]
            newVerts[j] = temp
        }
        return Self(newVerts)
    }
}

extension Geometry.Ngon where Scalar: FloatingPoint {

    @inlinable
    public func contains(_ point: Geometry.Point<2>) -> Bool {

        var inside = false
        var j = N - 1

        (0..<N).forEach { i in
            let vi = vertices[i]
            let vj = vertices[j]

            if (vi.y > point.y) != (vj.y > point.y) {

                let dx = (vj.x - vi.x).underlying
                let dy = (vj.y - vi.y).underlying
                let py = (point.y - vi.y).underlying
                let xIntersect = vi.x.underlying + dx / dy * py
                if point.x.underlying < xIntersect {
                    inside.toggle()
                }
            }
            j = i
        }

        return inside
    }
}

extension Geometry.Ngon where Scalar: FloatingPoint {

    @inlinable
    public func translated(by vector: Geometry.Vector<2>) -> Self {
        var newVerts = vertices
        (0..<N).forEach { i in
            newVerts[i] = vertices[i] + vector
        }
        return Self(newVerts)
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>) -> Self? {
        guard let center = centroid else { return nil }
        return scaled(by: factor, about: center)
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>, about point: Geometry.Point<2>) -> Self {
        var newVerts = vertices
        (0..<N).forEach { i in
            let v = vertices[i]

            let dx = factor * (v.x - point.x)
            let dy = factor * (v.y - point.y)
            newVerts[i] = Geometry.Point(x: point.x + dx, y: point.y + dy)
        }
        return Self(newVerts)
    }
}

extension Geometry.Ngon where Scalar == Double {

    @inlinable
    public static func regular(
        sideLength: Scalar,
        at center: Geometry.Point<2> = .zero
    ) -> Self {
        let piOverNValue: Scalar = Scalar.pi / Scalar(N)
        let piOverN = Radian<Scalar>(_unchecked: piOverNValue)
        let circumradius = sideLength / (Scalar(2) * piOverN.sin.value)
        var verts = InlineArray<N, Geometry.Point<2>>(repeating: center)
        (0..<N).forEach { i in
            let twoPi: Scalar = Scalar(2) * Scalar.pi
            let fraction: Scalar = Scalar(i) / Scalar(N)
            let angleValue: Scalar = twoPi * fraction
            let angle = Radian<Scalar>(_unchecked: angleValue)
            let dx = Linear<Scalar, Space>.Dx(_unchecked: circumradius * angle.cos.value)
            let dy = Linear<Scalar, Space>.Dy(_unchecked: circumradius * angle.sin.value)
            verts[i] = Geometry.Point(x: center.x + dx, y: center.y + dy)
        }
        return Self(verts)
    }

    @inlinable
    public static func regular(
        circumradius: Scalar,
        at center: Geometry.Point<2> = .zero
    ) -> Self {
        var verts = InlineArray<N, Geometry.Point<2>>(repeating: center)
        (0..<N).forEach { i in
            let twoPi: Scalar = Scalar(2) * Scalar.pi
            let fraction: Scalar = Scalar(i) / Scalar(N)
            let angleValue: Scalar = twoPi * fraction
            let angle = Radian<Scalar>(_unchecked: angleValue)
            let dx = Linear<Scalar, Space>.Dx(_unchecked: circumradius * angle.cos.value)
            let dy = Linear<Scalar, Space>.Dy(_unchecked: circumradius * angle.sin.value)
            verts[i] = Geometry.Point(x: center.x + dx, y: center.y + dy)
        }
        return Self(verts)
    }

    @inlinable
    public static func regular(
        inradius: Scalar,
        at center: Geometry.Point<2> = .zero
    ) -> Self {
        let piOverNValue: Scalar = Scalar.pi / Scalar(N)
        let piOverN = Radian<Scalar>(_unchecked: piOverNValue)
        let circumradius = inradius / piOverN.cos.value
        return regular(circumradius: circumradius, at: center)
    }
}

extension Geometry.Ngon where Scalar == Float {

    @inlinable
    public static func regular(
        sideLength: Scalar,
        at center: Geometry.Point<2> = .zero
    ) -> Self {
        let piOverNValue: Scalar = Scalar.pi / Scalar(N)
        let piOverN = Radian<Scalar>(_unchecked: piOverNValue)
        let circumradius = sideLength / (Scalar(2) * piOverN.sin.value)
        var verts = InlineArray<N, Geometry.Point<2>>(repeating: center)
        (0..<N).forEach { i in
            let twoPi: Scalar = Scalar(2) * Scalar.pi
            let fraction: Scalar = Scalar(i) / Scalar(N)
            let angleValue: Scalar = twoPi * fraction
            let angle = Radian<Scalar>(_unchecked: angleValue)
            let dx = Linear<Scalar, Space>.Dx(_unchecked: circumradius * angle.cos.value)
            let dy = Linear<Scalar, Space>.Dy(_unchecked: circumradius * angle.sin.value)
            verts[i] = Geometry.Point(x: center.x + dx, y: center.y + dy)
        }
        return Self(verts)
    }

    @inlinable
    public static func regular(
        circumradius: Scalar,
        at center: Geometry.Point<2> = .zero
    ) -> Self {
        var verts = InlineArray<N, Geometry.Point<2>>(repeating: center)
        (0..<N).forEach { i in
            let twoPi: Scalar = Scalar(2) * Scalar.pi
            let fraction: Scalar = Scalar(i) / Scalar(N)
            let angleValue: Scalar = twoPi * fraction
            let angle = Radian<Scalar>(_unchecked: angleValue)
            let dx = Linear<Scalar, Space>.Dx(_unchecked: circumradius * angle.cos.value)
            let dy = Linear<Scalar, Space>.Dy(_unchecked: circumradius * angle.sin.value)
            verts[i] = Geometry.Point(x: center.x + dx, y: center.y + dy)
        }
        return Self(verts)
    }

    @inlinable
    public static func regular(
        inradius: Scalar,
        at center: Geometry.Point<2> = .zero
    ) -> Self {
        let piOverNValue: Scalar = Scalar.pi / Scalar(N)
        let piOverN = Radian<Scalar>(_unchecked: piOverNValue)
        let circumradius = inradius / piOverN.cos.value
        return regular(circumradius: circumradius, at: center)
    }
}

extension Geometry where Scalar: FloatingPoint {

    @inlinable
    public static func area<let N: Int>(of ngon: Ngon<N>) -> Area {
        Area(abs(ngon.signedArea.underlying))
    }

    @inlinable
    public static func signedDoubleArea<let N: Int>(of ngon: Ngon<N>) -> Linear<Scalar, Space>.Area
    where Scalar: SignedNumeric {
        ngon.signedDoubleArea
    }

    @inlinable
    public static func perimeter<let N: Int>(of ngon: Ngon<N>) -> Perimeter {
        var sum: Distance = .zero
        (0..<N).forEach { i in
            let j = (i + 1) % N
            sum += ngon.vertices[i].distance(to: ngon.vertices[j])
        }
        return sum
    }

    @inlinable
    public static func centroid<let N: Int>(of ngon: Ngon<N>) -> Point<2>?
    where Scalar: SignedNumeric {

        let a = signedDoubleArea(of: ngon).underlying
        guard abs(a) > .ulpOfOne else { return nil }

        var cx: Scalar = .zero
        var cy: Scalar = .zero

        (0..<N).forEach { i in
            let j = (i + 1) % N
            let xi = ngon.vertices[i].x.underlying
            let yi = ngon.vertices[i].y.underlying
            let xj = ngon.vertices[j].x.underlying
            let yj = ngon.vertices[j].y.underlying
            let cross = xi * yj - xj * yi
            cx += (xi + xj) * cross
            cy += (yi + yj) * cross
        }

        let factor = Scalar(1) / (Scalar(3) * a)
        return Point(x: X(cx * factor), y: Y(cy * factor))
    }
}

extension Geometry.Ngon {

    @inlinable
    public var polygon: Geometry.Polygon {
        Geometry.Polygon(vertices: vertexArray)
    }
}

extension Geometry.Ngon {

    @inlinable
    public init<U, E: Swift.Error>(
        _ other: borrowing Geometry<U, Space>.Ngon<N>,
        _ transform: (U) throws(E) -> Scalar
    ) throws(E) {
        let first = try Geometry.Point<2>(other.vertices[0], transform)
        var result = InlineArray<N, Geometry.Point<2>>(repeating: first)
        for i in 1..<N {
            result[i] = try Geometry.Point<2>(other.vertices[i], transform)
        }
        self.init(result)
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Ngon<N> {
        let first = try vertices[0].map(transform)
        var result = InlineArray<N, Geometry<Result, Space>.Point<2>>(repeating: first)
        for i in 1..<N {
            result[i] = try vertices[i].map(transform)
        }
        return Geometry<Result, Space>.Ngon<N>(result)
    }
}

extension Geometry.Ngon where N == 4 {

    @inlinable
    public var a: Geometry.Point<2> {
        get { vertices[0] }
        set { vertices[0] = newValue }
    }

    @inlinable
    public var b: Geometry.Point<2> {
        get { vertices[1] }
        set { vertices[1] = newValue }
    }

    @inlinable
    public var c: Geometry.Point<2> {
        get { vertices[2] }
        set { vertices[2] = newValue }
    }

    @inlinable
    public var d: Geometry.Point<2> {
        get { vertices[3] }
        set { vertices[3] = newValue }
    }

    @inlinable
    public init(
        a: Geometry.Point<2>,
        b: Geometry.Point<2>,
        c: Geometry.Point<2>,
        d: Geometry.Point<2>
    ) {
        self.init([a, b, c, d])
    }
}

extension Geometry.Ngon where N == 4, Scalar: AdditiveArithmetic {

    @inlinable
    public var diagonals: (ac: Geometry.Line.Segment, bd: Geometry.Line.Segment) {
        (
            Geometry.Line.Segment(start: vertices[0], end: vertices[2]),
            Geometry.Line.Segment(start: vertices[1], end: vertices[3])
        )
    }
}

extension Geometry.Ngon where N == 4 {

    @inlinable
    public var triangles: (Geometry.Ngon<3>, Geometry.Ngon<3>) {
        (
            Geometry.Ngon<3>(a: vertices[0], b: vertices[1], c: vertices[2]),
            Geometry.Ngon<3>(a: vertices[0], b: vertices[2], c: vertices[3])
        )
    }
}

extension Geometry.Ngon where N == 3 {

    @inlinable
    public var a: Geometry.Point<2> {
        get { vertices[0] }
        set { vertices[0] = newValue }
    }

    @inlinable
    public var b: Geometry.Point<2> {
        get { vertices[1] }
        set { vertices[1] = newValue }
    }

    @inlinable
    public var c: Geometry.Point<2> {
        get { vertices[2] }
        set { vertices[2] = newValue }
    }

    @inlinable
    public init(
        a: consuming Geometry.Point<2>,
        b: consuming Geometry.Point<2>,
        c: consuming Geometry.Point<2>
    ) {
        self.init([a, b, c])
    }
}

extension Geometry.Ngon where N == 3, Scalar: FloatingPoint {

    @inlinable
    public var sideLengths: (ab: Geometry.Distance, bc: Geometry.Distance, ca: Geometry.Distance) {
        (
            vertices[0].distance(to: vertices[1]),
            vertices[1].distance(to: vertices[2]),
            vertices[2].distance(to: vertices[0])
        )
    }
}

extension Geometry.Ngon where N == 3, Scalar: FloatingPoint {

    @inlinable
    public var incircle: Geometry.Circle? { .incircle(of: self) }
}

extension Geometry.Ngon where N == 3, Scalar: FloatingPoint {

    @inlinable
    public var circumcircle: Geometry.Circle? { .circumcircle(of: self) }
}

extension Geometry.Ngon where N == 3, Scalar: FloatingPoint {

    @inlinable
    public var orthocenter: Geometry.Point<2>? {

        guard let cc = circumcircle else { return nil }

        let ax = vertices[0].x.underlying
        let ay = vertices[0].y.underlying
        let bx = vertices[1].x.underlying
        let by = vertices[1].y.underlying
        let cx = vertices[2].x.underlying
        let cy = vertices[2].y.underlying
        let ccx = cc.center.x.underlying
        let ccy = cc.center.y.underlying

        let ox = ax + bx + cx - Scalar(2) * ccx
        let oy = ay + by + cy - Scalar(2) * ccy

        return Geometry.Point(x: Geometry.X(_unchecked: ox), y: Geometry.Y(_unchecked: oy))
    }
}

extension Geometry.Ngon where N == 3, Scalar == Double {

    @inlinable
    public var angles: (atA: Radian<Scalar>, atB: Radian<Scalar>, atC: Radian<Scalar>) {

        let sides = sideLengths
        let ab = sides.ab.underlying
        let bc = sides.bc.underlying
        let ca = sides.ca.underlying

        let abSq = ab * ab
        let bcSq = bc * bc
        let caSq = ca * ca

        let cosANum = caSq + abSq - bcSq
        let cosADen = 2 * ca * ab
        let cosA = cosANum / cosADen

        let cosBNum = abSq + bcSq - caSq
        let cosBDen = 2 * ab * bc
        let cosB = cosBNum / cosBDen

        let cosCNum = bcSq + caSq - abSq
        let cosCDen = 2 * bc * ca
        let cosC = cosCNum / cosCDen

        return (
            Radian.acos(Scale<1, Scalar>(cosA)),
            Radian.acos(Scale<1, Scalar>(cosB)),
            Radian.acos(Scale<1, Scalar>(cosC))
        )
    }
}

extension Geometry.Ngon where N == 3, Scalar == Float {

    @inlinable
    public var angles: (atA: Radian<Scalar>, atB: Radian<Scalar>, atC: Radian<Scalar>) {

        let sides = sideLengths
        let ab = sides.ab.underlying
        let bc = sides.bc.underlying
        let ca = sides.ca.underlying

        let abSq = ab * ab
        let bcSq = bc * bc
        let caSq = ca * ca

        let cosANum = caSq + abSq - bcSq
        let cosADen: Float = 2 * ca * ab
        let cosA = cosANum / cosADen

        let cosBNum = abSq + bcSq - caSq
        let cosBDen: Float = 2 * ab * bc
        let cosB = cosBNum / cosBDen

        let cosCNum = bcSq + caSq - abSq
        let cosCDen: Float = 2 * bc * ca
        let cosC = cosCNum / cosCDen

        return (
            Radian.acos(Scale<1, Scalar>(cosA)),
            Radian.acos(Scale<1, Scalar>(cosB)),
            Radian.acos(Scale<1, Scalar>(cosC))
        )
    }
}

extension Geometry.Ngon where N == 3, Scalar: FloatingPoint {

    @inlinable
    public func barycentric(_ point: Geometry.Point<2>) -> (u: Scalar, v: Scalar, w: Scalar)? {
        let v0: Geometry.Vector<2> = Geometry.Vector(
            dx: vertices[2].x - vertices[0].x,
            dy: vertices[2].y - vertices[0].y
        )
        let v1: Geometry.Vector<2> = Geometry.Vector(
            dx: vertices[1].x - vertices[0].x,
            dy: vertices[1].y - vertices[0].y
        )
        let v2: Geometry.Vector<2> = Geometry.Vector(
            dx: point.x - vertices[0].x,
            dy: point.y - vertices[0].y
        )

        let dot00: Scalar = v0.dot(v0)
        let dot01: Scalar = v0.dot(v1)
        let dot02: Scalar = v0.dot(v2)
        let dot11: Scalar = v1.dot(v1)
        let dot12: Scalar = v1.dot(v2)

        let denom: Scalar = dot00 * dot11 - dot01 * dot01
        guard abs(denom) > Scalar.ulpOfOne else { return nil }

        let one: Scalar = Scalar(1)
        let invDenom: Scalar = one / denom
        let v: Scalar = (dot11 * dot02 - dot01 * dot12) * invDenom
        let u: Scalar = (dot00 * dot12 - dot01 * dot02) * invDenom
        let w: Scalar = one - u - v

        return (w, u, v)
    }

    @inlinable
    public func point(u: Scalar, v: Scalar, w: Scalar) -> Geometry.Point<2> {

        let vScale = Scale<1, Scalar>(v)
        let wScale = Scale<1, Scalar>(w)
        let abDeltaX = vertices[1].x - vertices[0].x
        let abDeltaY = vertices[1].y - vertices[0].y
        let acDeltaX = vertices[2].x - vertices[0].x
        let acDeltaY = vertices[2].y - vertices[0].y
        return Geometry.Point(
            x: vertices[0].x + vScale * abDeltaX + wScale * acDeltaX,
            y: vertices[0].y + vScale * abDeltaY + wScale * acDeltaY
        )
    }
}

extension Geometry.Ngon where N == 3, Scalar: FloatingPoint {

    @inlinable
    public func containsBarycentric(_ point: Geometry.Point<2>) -> Bool {
        guard let bary = barycentric(point) else { return false }
        let zero: Scalar = Scalar(0)
        return bary.u >= zero && bary.v >= zero && bary.w >= zero
    }
}

extension Geometry.Ngon where N == 3, Scalar: FloatingPoint & AdditiveArithmetic {

    @inlinable
    public static func right(
        base: Scalar,
        height: Scalar,
        at origin: Geometry.Point<2> = .zero
    ) -> Self {
        Self(
            a: origin,
            b: Geometry.Point(x: origin.x + Linear<Scalar, Space>.Dx(_unchecked: base), y: origin.y),
            c: Geometry.Point(x: origin.x, y: origin.y + Linear<Scalar, Space>.Dy(_unchecked: height))
        )
    }

    @inlinable
    public static func equilateral(
        sideLength: Scalar,
        at origin: Geometry.Point<2> = .zero
    ) -> Self {
        let half = sideLength / Scalar(2)

        let h = sideLength * Scalar(3).squareRoot() / Scalar(2)
        return Self(
            a: origin,
            b: Geometry.Point(x: origin.x + Linear<Scalar, Space>.Dx(_unchecked: sideLength), y: origin.y),
            c: Geometry.Point(
                x: origin.x + Linear<Scalar, Space>.Dx(_unchecked: half),
                y: origin.y + Linear<Scalar, Space>.Dy(_unchecked: h)
            )
        )
    }

    @inlinable
    public static func isosceles(
        base: Scalar,
        leg: Scalar,
        at origin: Geometry.Point<2> = .zero
    ) -> Self? {

        let half = base / Scalar(2)
        let hSquared = leg * leg - half * half
        guard hSquared >= Scalar(0) else { return nil }
        let h = hSquared.squareRoot()
        return Self(
            a: origin,
            b: Geometry.Point(x: origin.x + Linear<Scalar, Space>.Dx(_unchecked: base), y: origin.y),
            c: Geometry.Point(
                x: origin.x + Linear<Scalar, Space>.Dx(_unchecked: half),
                y: origin.y + Linear<Scalar, Space>.Dy(_unchecked: h)
            )
        )
    }
}

extension Geometry.Ngon where N == 3, Scalar: FloatingPoint {

    @inlinable
    public var centroid: Geometry.Point<2> {

        let oneThird = Scale<1, Scalar>(1 / Scalar(3))
        let dx = (vertices[1].x - vertices[0].x) + (vertices[2].x - vertices[0].x)
        let dy = (vertices[1].y - vertices[0].y) + (vertices[2].y - vertices[0].y)
        return Geometry.Point(x: vertices[0].x + oneThird * dx, y: vertices[0].y + oneThird * dy)
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>) -> Self {
        scaled(by: factor, about: centroid)
    }
}

extension Geometry {

    public typealias Triangle = Ngon<3>
}

extension Geometry.Edges {

        @inlinable
        public subscript(index: Int) -> Geometry.Line.Segment {
            get { segments[index] }
            set { segments[index] = newValue }
        }}
