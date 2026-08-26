extension Geometry {

    public struct Insets {

        public var top: Height

        public var leading: Width

        public var bottom: Height

        public var trailing: Width

        @inlinable
        public init(
            top: consuming Height,
            leading: consuming Width,
            bottom: consuming Height,
            trailing: consuming Width
        ) {
            self.top = top
            self.leading = leading
            self.bottom = bottom
            self.trailing = trailing
        }
    }
}

extension Geometry.Insets: Sendable where Scalar: Sendable {}
extension Geometry.Insets: Equatable where Scalar: Equatable {}
extension Geometry.Insets: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Insets: Codable where Scalar: Codable {
        private enum CodingKeys: String, CodingKey {
            case top, leading, bottom, trailing
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.top = try container.decode(Geometry.Height.self, forKey: .top)
            self.leading = try container.decode(Geometry.Width.self, forKey: .leading)
            self.bottom = try container.decode(Geometry.Height.self, forKey: .bottom)
            self.trailing = try container.decode(Geometry.Width.self, forKey: .trailing)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(top, forKey: .top)
            try container.encode(leading, forKey: .leading)
            try container.encode(bottom, forKey: .bottom)
            try container.encode(trailing, forKey: .trailing)
        }
    }
#endif

extension Geometry.Insets where Scalar: AdditiveArithmetic {

    @inlinable
    public init(all: Scalar) {
        self.top = Geometry.Height(all)
        self.leading = Geometry.Width(all)
        self.bottom = Geometry.Height(all)
        self.trailing = Geometry.Width(all)
    }

    @inlinable
    public init(horizontal: Geometry.Width, vertical: Geometry.Height) {
        self.top = vertical
        self.leading = horizontal
        self.bottom = vertical
        self.trailing = horizontal
    }
}

extension Geometry.Insets where Scalar: AdditiveArithmetic {

    @inlinable
    public static var zero: Self {
        Self(top: .zero, leading: .zero, bottom: .zero, trailing: .zero)
    }
}

extension Geometry.Insets {

    @inlinable
    public init<U, E: Swift.Error>(
        _ other: borrowing Geometry<U, Space>.Insets,
        _ transform: (U) throws(E) -> Scalar
    ) throws(E) {
        self.init(
            top: try other.top.map(transform),
            leading: try other.leading.map(transform),
            bottom: try other.bottom.map(transform),
            trailing: try other.trailing.map(transform)
        )
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Insets {
        Geometry<Result, Space>.Insets(
            top: try top.map(transform),
            leading: try leading.map(transform),
            bottom: try bottom.map(transform),
            trailing: try trailing.map(transform)
        )
    }
}

extension Geometry.Insets where Scalar: AdditiveArithmetic {

    @inlinable
    public static func combined(_ lhs: borrowing Self, _ rhs: borrowing Self) -> Self {
        Self(
            top: lhs.top + rhs.top,
            leading: lhs.leading + rhs.leading,
            bottom: lhs.bottom + rhs.bottom,
            trailing: lhs.trailing + rhs.trailing
        )
    }
}

extension Geometry.Insets where Scalar: AdditiveArithmetic {

    @inlinable
    public var horizontal: Geometry.Width { leading + trailing }

    @inlinable
    public var vertical: Geometry.Height { top + bottom }
}
