#if Affine
@_exported public import Affine
@_exported public import Point
@_exported public import Displacement
@_exported public import Orthotope
@_exported public import Segment
public import Vector
public import Space
public import Scale
public import Linear
public import Tagged

extension Geometry {
    public typealias X = Space::Coordinate.X<Space>.Value<Scalar>
    public typealias Y = Space::Coordinate.Y<Space>.Value<Scalar>
    public typealias Z = Space::Coordinate.Z<Space>.Value<Scalar>

    /// A geometry-domain position backed by the canonical Point value.
    /// Space remains part of stored Tagged identity; no implicit affine transform is installed.
    public struct Point<let N: Int> {
        public var position: Tagged<Space, Point::Point<N, Scalar>>
        @inlinable public init(_ position: Tagged<Space, Point::Point<N, Scalar>>) { self.position = position }
        @inlinable public init(_ coordinates: InlineArray<N, Scalar>) {
            position = .init(_unchecked: Point::Point(coordinates: Vector::Vector(coordinates)))
        }
        public var coordinates: InlineArray<N, Scalar> {
            get { position.underlying.coordinates.components }
            set { position = .init(_unchecked: Point::Point(coordinates: Vector::Vector(newValue))) }
        }
        public subscript(index: Int) -> Scalar {
            get { position.underlying[index] }
            set { var values = coordinates; values[index] = newValue; coordinates = values }
        }
        public init<U, E: Swift.Error>(_ other: Geometry<U, Space>.Point<N>, _ transform: (U) throws(E) -> Scalar) throws(E) {
            let values: InlineArray<N, Scalar> = try InlineArray { (i: Int) throws(E) in try transform(other[i]) }
            self.init(values)
        }
        public func map<Result, E: Swift.Error>(_ transform: (Scalar) throws(E) -> Result) throws(E) -> Geometry<Result, Space>.Point<N> {
            try .init(self, transform)
        }
        public func translated<Failure: Swift.Error>(by offset: Displacement::Displacement<N, Scalar>,
            using relationship: Affine<Self, Displacement::Displacement<N, Scalar>, Failure>) throws(Failure) -> Self {
            try relationship.translated(self, by: offset)
        }
    }
}
extension Geometry.Point: Equatable where Scalar: Equatable {}
extension Geometry.Point: Hashable where Scalar: Hashable {}
extension Geometry.Point: Sendable where Scalar: Sendable {}
#if !hasFeature(Embedded)
extension Geometry.Point: Encodable where Scalar: Encodable {
    public func encode(to encoder: any Encoder) throws {
        try position.underlying.coordinates.encode(to: encoder)
    }
}
extension Geometry.Point: Decodable where Scalar: Decodable {
    public init(from decoder: any Decoder) throws {
        self.init(try Vector::Vector<N, Scalar>(from: decoder).components)
    }
}
#endif
extension Geometry.Point where Scalar: AdditiveArithmetic {
    public static var zero: Self { .init(InlineArray(repeating: .zero)) }
    /// Explicitly chooses componentwise Cartesian addition on the canonical Point.
    public static var cartesian: Affine<Self, Displacement::Displacement<N, Scalar>, Never> {
        let canonical = Point::Point<N, Scalar>.cartesian
        return .init(
            translating: { point, delta in .init(.init(_unchecked: canonical.translated(point.position.underlying, by: delta))) },
            displacement: { start, end in canonical.displacement(from: start.position.underlying, to: end.position.underlying) })
    }
}
extension Geometry.Point where Scalar: FloatingPoint {
    public func distance(to other: Self) -> Geometry.Length {
        var squared: Scalar = .zero
        for i in 0..<N { let d = other[i] - self[i]; squared += d*d }
        return Geometry.Length(squared.squareRoot())
    }
    public func lerp(to other: Self, t: Scale<1, Scalar>) -> Self {
        .init(InlineArray { self[$0] + (other[$0] - self[$0]) * t.value })
    }
}
extension Geometry.Point where N == 1 {
    public var x: Geometry.X { get { .init(_unchecked: self[0]) } set { self[0] = newValue.underlying } }
    public init(x: Geometry.X) { self.init([x.underlying]) }
}
extension Geometry.Point where N == 2 {
    public var x: Geometry.X { get { .init(_unchecked: self[0]) } set { self[0] = newValue.underlying } }
    public var y: Geometry.Y { get { .init(_unchecked: self[1]) } set { self[1] = newValue.underlying } }
    public init(x: Geometry.X, y: Geometry.Y) { self.init([x.underlying, y.underlying]) }
}
extension Geometry.Point where N == 3 {
    public var x: Geometry.X { get { .init(_unchecked: self[0]) } set { self[0] = newValue.underlying } }
    public var y: Geometry.Y { get { .init(_unchecked: self[1]) } set { self[1] = newValue.underlying } }
    public var z: Geometry.Z { get { .init(_unchecked: self[2]) } set { self[2] = newValue.underlying } }
    public init(x: Geometry.X, y: Geometry.Y, z: Geometry.Z) { self.init([x.underlying, y.underlying, z.underlying]) }
}
#endif
