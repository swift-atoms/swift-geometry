public import Affine_Geometry_Primitives
public import Dimension_Primitives
public import Linear_Primitives

extension Geometry {

    public struct Hypercube<let N: Int> {

        public var center: Point<N>

        public var halfSide: Linear<Scalar, Space>.Magnitude

        @inlinable
        public init(center: consuming Point<N>, halfSide: consuming Linear<Scalar, Space>.Magnitude) {
            self.center = center
            self.halfSide = halfSide
        }
    }
}

extension Geometry {

    public typealias Square = Hypercube<2>

    public typealias Cube = Hypercube<3>
}

extension Geometry.Hypercube: Sendable where Scalar: Sendable {}
extension Geometry.Hypercube: Equatable where Scalar: Equatable {}
extension Geometry.Hypercube: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Hypercube: Codable where Scalar: Codable {}
#endif

extension Geometry.Hypercube where Scalar: AdditiveArithmetic {

    @inlinable
    public init(halfSide: Linear<Scalar, Space>.Magnitude) {
        self.init(center: .zero, halfSide: halfSide)
    }
}

extension Geometry.Hypercube where Scalar: FloatingPoint {

    @inlinable
    public init(center: consuming Geometry.Point<N>, side: Linear<Scalar, Space>.Magnitude) {
        self.init(center: center, halfSide: Linear<Scalar, Space>.Magnitude(side.underlying / 2))
    }

    @inlinable
    public init(side: Linear<Scalar, Space>.Magnitude) where Scalar: AdditiveArithmetic {
        self.init(center: .zero, halfSide: Linear<Scalar, Space>.Magnitude(side.underlying / 2))
    }
}

extension Geometry.Hypercube where Scalar: ExpressibleByIntegerLiteral & AdditiveArithmetic {

    @inlinable
    public static var unit: Self {
        Self(center: .zero, halfSide: .init(1))
    }
}

extension Geometry.Hypercube where Scalar: FloatingPoint {

    @inlinable
    public var side: Geometry.Magnitude {
        Geometry.Magnitude(Linear<Scalar, Space>.Magnitude(halfSide.underlying * 2))
    }
}

extension Geometry.Hypercube where N == 2, Scalar: FloatingPoint {

    @inlinable
    public var diagonal: Geometry.Magnitude {
        let s = halfSide.underlying * 2
        return Geometry.Magnitude(Linear<Scalar, Space>.Magnitude(s * Scalar(2).squareRoot()))
    }

    @inlinable
    public var area: Geometry.Area {
        let s = halfSide.underlying * 2
        return Geometry.Area(s * s)
    }

    @inlinable
    public var perimeter: Geometry.Perimeter {
        Geometry.Perimeter(halfSide.underlying * 8)
    }

    @inlinable
    public var boundingBox: Geometry.Rectangle {
        Geometry.Rectangle(
            llx: center.x - halfSide,
            lly: center.y - halfSide,
            urx: center.x + halfSide,
            ury: center.y + halfSide
        )
    }
}

extension Geometry.Hypercube where N == 2, Scalar: FloatingPoint {

    @inlinable
    public var llx: Geometry.X {
        center.x - halfSide
    }

    @inlinable
    public var lly: Geometry.Y {
        center.y - halfSide
    }

    @inlinable
    public var urx: Geometry.X {
        center.x + halfSide
    }

    @inlinable
    public var ury: Geometry.Y {
        center.y + halfSide
    }

    @inlinable
    public var width: Geometry.Width {
        Geometry.Width(halfSide.underlying * 2)
    }

    @inlinable
    public var height: Geometry.Height {
        Geometry.Height(halfSide.underlying * 2)
    }
}

extension Geometry.Hypercube where N == 3, Scalar: FloatingPoint {

    @inlinable
    public var diagonal: Geometry.Magnitude {
        let s = halfSide.underlying * 2
        return Geometry.Magnitude(Linear<Scalar, Space>.Magnitude(s * Scalar(3).squareRoot()))
    }

    @inlinable
    public var volume: Scalar {
        let s = halfSide.underlying * 2
        return s * s * s
    }

    @inlinable
    public var surfaceArea: Scalar {
        let s = halfSide.underlying * 2
        return 6 * s * s
    }
}

extension Geometry.Hypercube where N == 2, Scalar: FloatingPoint {

    @inlinable
    public func contains(_ point: Geometry.Point<2>) -> Bool {
        let h = halfSide.underlying
        let dx = point.x.underlying - center.x.underlying
        let dy = point.y.underlying - center.y.underlying
        return dx >= -h && dx <= h && dy >= -h && dy <= h
    }
}

extension Geometry.Hypercube where N == 2, Scalar: FloatingPoint {

    @inlinable
    public func translated(by vector: Geometry.Vector<2>) -> Self {
        Self(center: center + vector, halfSide: halfSide)
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>) -> Self {
        Self(
            center: center,
            halfSide: Linear<Scalar, Space>.Magnitude(halfSide.underlying * factor.value)
        )
    }
}

extension Geometry.Hypercube {

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Hypercube<N> {
        Geometry<Result, Space>.Hypercube(
            center: try center.map(transform),
            halfSide: try halfSide.map(transform)
        )
    }
}
