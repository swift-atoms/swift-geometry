public import Inset
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
