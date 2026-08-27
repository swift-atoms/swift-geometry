public import Affine
import Dimension
public import Linear
public import Tagged

public enum Geometry<Scalar: ~Copyable, Space>: ~Copyable {}

extension Geometry: Copyable where Scalar: Copyable {}
extension Geometry: Sendable where Scalar: Sendable {}

extension Geometry {

    public typealias Area = Linear<Scalar, Space>.Area
}

extension Geometry {

    public typealias X = Affine.Continuous<Scalar, Space>.X

    public typealias Y = Affine.Continuous<Scalar, Space>.Y

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

    public typealias Translation = Affine.Continuous<Scalar, Space>.Translation

    public typealias Transform = Affine.Continuous<Scalar, Space>.Transform

    public typealias Point<let N: Int> = Affine.Continuous<Scalar, Space>.Point<N>

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
    extension Geometry.Magnitude: Codable where Scalar: Codable {

        private enum CodingKeys: String, CodingKey {
            case underlying
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.init(
                .init(_unchecked: try container.decode(Scalar.self, forKey: .underlying))
            )
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(underlying.underlying, forKey: .underlying)
        }
    }
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
        self.underlying = .init(_unchecked: Scalar(integerLiteral: value))
    }
}

extension Geometry.Magnitude: ExpressibleByFloatLiteral where Scalar: ExpressibleByFloatLiteral {

    @inlinable
    public init(floatLiteral value: Scalar.FloatLiteralType) {
        self.underlying = .init(_unchecked: Scalar(floatLiteral: value))
    }
}

extension Geometry.Magnitude {

    @inlinable
    public var width: Geometry.Width {
        Geometry.Width(_unchecked: underlying.underlying)
    }

    @inlinable
    public var height: Geometry.Height {
        Geometry.Height(_unchecked: underlying.underlying)
    }

    @inlinable
    public var value: Scalar {
        underlying.underlying
    }
}

extension Geometry.Magnitude where Scalar: AdditiveArithmetic {

    @inlinable
    public static var zero: Self {
        Self(Linear<Scalar, Space>.Magnitude(_unchecked: .zero))
    }
}
