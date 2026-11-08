public import Linear

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
