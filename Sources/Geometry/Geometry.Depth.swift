extension Geometry {

    public struct Depth {

        public var value: Scalar

        @inlinable
        public init(_ value: consuming Scalar) {
            self.value = value
        }
    }
}

extension Geometry.Depth: Sendable where Scalar: Sendable {}
extension Geometry.Depth: Equatable where Scalar: Equatable {}
extension Geometry.Depth: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Depth: Codable where Scalar: Codable {}
#endif

extension Geometry.Depth where Scalar: AdditiveArithmetic {

    @inlinable
    public static var zero: Self {
        Self(.zero)
    }
}

extension Geometry.Depth: ExpressibleByIntegerLiteral where Scalar: ExpressibleByIntegerLiteral {

    @inlinable
    public init(integerLiteral value: Scalar.IntegerLiteralType) {
        self.value = Scalar(integerLiteral: value)
    }
}

extension Geometry.Depth: ExpressibleByFloatLiteral where Scalar: ExpressibleByFloatLiteral {

    @inlinable
    public init(floatLiteral value: Scalar.FloatLiteralType) {
        self.value = Scalar(floatLiteral: value)
    }
}

extension Geometry.Depth: Strideable where Scalar: Strideable {

    public typealias Stride = Scalar.Stride

    @inlinable
    public func distance(to other: Self) -> Stride {
        value.distance(to: other.value)
    }

    @inlinable
    public func advanced(by n: Stride) -> Self {
        Self(value.advanced(by: n))
    }
}

extension Geometry.Depth {

    @inlinable
    public init<U, E: Swift.Error>(
        _ other: borrowing Geometry<U, Space>.Depth,
        _ transform: (U) throws(E) -> Scalar
    ) throws(E) {
        self.init(try transform(other.value))
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Depth {
        Geometry<Result, Space>.Depth(try transform(value))
    }
}
