import Dimension
import Linear
public import Tagged

extension Geometry {

    public struct Size<let N: Int> {

        public var dimensions: InlineArray<N, Scalar>

        @inlinable
        public init(_ dimensions: consuming InlineArray<N, Scalar>) {
            self.dimensions = dimensions
        }
    }
}

extension Geometry.Size: Sendable where Scalar: Sendable {}

extension Geometry.Size: Equatable where Scalar: Equatable {

    @inlinable
    public static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        for i in 0..<N {
            if lhs.dimensions[i] != rhs.dimensions[i] {
                return false
            }
        }
        return true
    }
}

extension Geometry.Size: Hashable where Scalar: Hashable {

    @inlinable
    public func hash(into hasher: inout Hasher) {
        (0..<N).forEach { i in
            hasher.combine(dimensions[i])
        }
    }
}

#if !hasFeature(Embedded)
    extension Geometry.Size: Codable where Scalar: Codable {

        public init(from decoder: any Decoder) throws {
            var container = try decoder.unkeyedContainer()
            var dimensions = InlineArray<N, Scalar>(repeating: try container.decode(Scalar.self))
            for i in 1..<N {
                dimensions[i] = try container.decode(Scalar.self)
            }
            self.dimensions = dimensions
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.unkeyedContainer()
            for i in 0..<N {
                try container.encode(dimensions[i])
            }
        }
    }
#endif

extension Geometry.Size {

    @inlinable
    public subscript(index: Int) -> Scalar {
        get { dimensions[index] }
        set { dimensions[index] = newValue }
    }
}

extension Geometry.Size {

    @inlinable
    public init<U, E: Swift.Error>(
        _ other: borrowing Geometry<U, Space>.Size<N>,
        _ transform: (U) throws(E) -> Scalar
    ) throws(E) {
        var dims = InlineArray<N, Scalar>(repeating: try transform(other.dimensions[0]))
        for i in 1..<N {
            dims[i] = try transform(other.dimensions[i])
        }
        self.init(dims)
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Size<N> {
        var result = InlineArray<N, Result>(repeating: try transform(dimensions[0]))
        for i in 1..<N {
            result[i] = try transform(dimensions[i])
        }
        return Geometry<Result, Space>.Size<N>(result)
    }
}

extension Geometry.Size where Scalar: AdditiveArithmetic {

    @inlinable
    public static var zero: Self {
        Self(InlineArray(repeating: .zero))
    }
}

extension Geometry.Size where N == 1 {

    @inlinable
    public var length: Geometry.Length {
        get { Geometry.Length(_unchecked: dimensions[0]) }
        set { dimensions[0] = newValue.underlying }
    }

    @inlinable
    public var width: Geometry.Width {
        get { Geometry.Width(_unchecked: dimensions[0]) }
        set { dimensions[0] = newValue.underlying }
    }

    @inlinable
    public var height: Geometry.Height {
        get { Geometry.Height(_unchecked: dimensions[0]) }
        set { dimensions[0] = newValue.underlying }
    }

    @inlinable
    public init(_ value: Scalar) {
        self.init([value])
    }
}

extension Geometry.Size where N == 1, Scalar: AdditiveArithmetic {

    @inlinable
    public var horizontal: Geometry.Width {
        Geometry.Width(_unchecked: dimensions[0] + dimensions[0])
    }

    @inlinable
    public var vertical: Geometry.Height {
        Geometry.Height(_unchecked: dimensions[0] + dimensions[0])
    }
}

extension Geometry.Size where N == 2 {

    @inlinable
    public var width: Geometry.Width {
        get { Geometry.Width(_unchecked: dimensions[0]) }
        set { dimensions[0] = newValue.underlying }
    }

    @inlinable
    public var height: Geometry.Height {
        get { Geometry.Height(_unchecked: dimensions[1]) }
        set { dimensions[1] = newValue.underlying }
    }

    @inlinable
    public init(width: Geometry.Width, height: Geometry.Height) {
        self.init([width.underlying, height.underlying])
    }
}

extension Geometry.Size where N == 3 {

    @inlinable
    public var width: Geometry.Width {
        get { .init(_unchecked: dimensions[0]) }
        set { dimensions[0] = newValue.underlying }
    }

    @inlinable
    public var height: Geometry.Height {
        get { .init(_unchecked: dimensions[1]) }
        set { dimensions[1] = newValue.underlying }
    }

    @inlinable
    public var depth: Scalar {
        get { dimensions[2] }
        set { dimensions[2] = newValue }
    }

    @inlinable
    public init(width: Geometry.Width, height: Geometry.Height, depth: Scalar) {
        self.init([width.underlying, height.underlying, depth])
    }

    @inlinable
    public init(_ size2: Geometry.Size<2>, depth: Scalar) {
        self.init(width: size2.width, height: size2.height, depth: depth)
    }
}

extension Geometry.Size {

    @inlinable
    public static func zip(_ a: Self, _ b: Self, _ combine: (Scalar, Scalar) -> Scalar) -> Self {
        var result = a.dimensions
        (0..<N).forEach { i in
            result[i] = combine(a.dimensions[i], b.dimensions[i])
        }
        return Self(result)
    }
}

extension Geometry.Size: ExpressibleByIntegerLiteral
where N == 1, Scalar: ExpressibleByIntegerLiteral {

    @inlinable
    public init(integerLiteral value: Scalar.IntegerLiteralType) {
        self.init([Scalar(integerLiteral: value)])
    }
}

extension Geometry.Size: ExpressibleByFloatLiteral where N == 1, Scalar: ExpressibleByFloatLiteral {

    @inlinable
    public init(floatLiteral value: Scalar.FloatLiteralType) {
        self.init([Scalar(floatLiteral: value)])
    }
}
