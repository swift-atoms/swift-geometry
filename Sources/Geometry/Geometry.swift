public import Linear

public enum Geometry<Scalar: ~Copyable, Space>: ~Copyable {}

extension Geometry: Copyable where Scalar: Copyable {}
extension Geometry: Sendable where Scalar: Sendable {}

extension Geometry {

    public typealias Area = Linear<Scalar, Space>.Area
}

extension Geometry {

    public typealias Width = Linear<Scalar, Space>.Width

    public typealias Height = Linear<Scalar, Space>.Height

    public typealias Dx = Linear<Scalar, Space>.Dx

    public typealias Dy = Linear<Scalar, Space>.Dy

    public typealias Length = Linear<Scalar, Space>.Magnitude

    public typealias Radius = Linear<Scalar, Space>.Magnitude

    public typealias Diameter = Linear<Scalar, Space>.Magnitude

    public typealias Distance = Linear<Scalar, Space>.Magnitude

    public typealias Circumference = Linear<Scalar, Space>.Magnitude

    public typealias Perimeter = Linear<Scalar, Space>.Magnitude

    public typealias ArcLength = Linear<Scalar, Space>.Magnitude

    public typealias Vector<let N: Int> = Linear<Scalar, Space>.Vector<N>
}

extension Geometry {

    public struct Magnitude {

        public var underlying: Linear<Scalar, Space>.Magnitude

        @inlinable
        public init(_ rawValue: Linear<Scalar, Space>.Magnitude) {
            self.underlying = rawValue
        }
    }
}

extension Geometry.Magnitude: Sendable where Scalar: Sendable {}
extension Geometry.Magnitude: Equatable where Scalar: Equatable {}
extension Geometry.Magnitude: Hashable where Scalar: Hashable {}
#if !hasFeature(Embedded)
    extension Geometry.Magnitude: Codable where Scalar: Codable {}
#endif

extension Geometry.Magnitude: Comparable where Scalar: Comparable {

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.underlying < rhs.underlying
    }
}

extension Geometry.Magnitude: ExpressibleByIntegerLiteral
where Scalar: ExpressibleByIntegerLiteral {

    @inlinable
    public init(integerLiteral value: Scalar.IntegerLiteralType) {
        self.underlying = .init(Scalar(integerLiteral: value))
    }
}

extension Geometry.Magnitude: ExpressibleByFloatLiteral where Scalar: ExpressibleByFloatLiteral {

    @inlinable
    public init(floatLiteral value: Scalar.FloatLiteralType) {
        self.underlying = .init(Scalar(floatLiteral: value))
    }
}

extension Geometry.Magnitude {

    @inlinable
    public var width: Geometry.Width {
        Geometry.Width(underlying.underlying)
    }

    @inlinable
    public var height: Geometry.Height {
        Geometry.Height(underlying.underlying)
    }

    @inlinable
    public var value: Scalar {
        underlying.underlying
    }
}

extension Geometry.Magnitude where Scalar: AdditiveArithmetic {

    @inlinable
    public static var zero: Self {
        Self(Linear<Scalar, Space>.Magnitude(.zero))
    }
}
