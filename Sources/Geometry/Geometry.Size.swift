public import Vector
public import Linear
public import Spatial

extension Geometry {

    public struct Size<let N: Int> {

        @usableFromInline
        internal var _storage: Vector::Vector<N, Scalar>

        public var dimensions: InlineArray<N, Scalar> {
            get { _storage.components }
            set { _storage.components = newValue }
        }

        @inlinable
        public init(_ dimensions: consuming InlineArray<N, Scalar>) {
            self._storage = Vector::Vector(dimensions)
        }
    }
}

extension Geometry.Size: Sendable where Scalar: Sendable {}

extension Geometry.Size: Equatable where Scalar: Equatable {

    @inlinable
    public static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        lhs._storage == rhs._storage
    }
}

extension Geometry.Size: Hashable where Scalar: Hashable {

    @inlinable
    public func hash(into hasher: inout Hasher) {
        _storage.hash(into: &hasher)
    }
}

#if !hasFeature(Embedded)
extension Geometry.Size: Decodable where Scalar: Decodable {
    public init(from decoder: any Decoder) throws {
        self.init(try Vector::Vector<N, Scalar>(from: decoder).components)
    }
}

extension Geometry.Size: Encodable where Scalar: Encodable {
    public func encode(to encoder: any Encoder) throws {
        try _storage.encode(to: encoder)
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
        let source = other.dimensions
        let dimensions: InlineArray<N, Scalar> = try InlineArray { index throws(E) in
            try transform(source[index])
        }
        self.init(dimensions)
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Size<N> {
        try Geometry<Result, Space>.Size<N>(self, transform)
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
        get { Geometry.Length(dimensions[0]) }
        set { dimensions[0] = newValue.underlying }
    }

    @inlinable
    public var width: Geometry.Width {
        get { Geometry.Width(dimensions[0]) }
        set { dimensions[0] = newValue.underlying }
    }

    @inlinable
    public var height: Geometry.Height {
        get { Geometry.Height(dimensions[0]) }
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
        Geometry.Width(dimensions[0] + dimensions[0])
    }

    @inlinable
    public var vertical: Geometry.Height {
        Geometry.Height(dimensions[0] + dimensions[0])
    }
}

extension Geometry.Size where N == 2 {

    @inlinable
    public var width: Geometry.Width {
        get { Geometry.Width(dimensions[0]) }
        set { dimensions[0] = newValue.underlying }
    }

    @inlinable
    public var height: Geometry.Height {
        get { Geometry.Height(dimensions[1]) }
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
        get { .init(dimensions[0]) }
        set { dimensions[0] = newValue.underlying }
    }

    @inlinable
    public var height: Geometry.Height {
        get { .init(dimensions[1]) }
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
