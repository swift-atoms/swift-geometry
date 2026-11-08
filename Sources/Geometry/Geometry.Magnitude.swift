public import Linear
public import Inset


extension Geometry {
    public struct Magnitude {

        public var underlying: Linear<Scalar, Space>.Magnitude

        @inlinable
        public init(_ rawValue: Linear<Scalar, Space>.Magnitude) {
            self.underlying = rawValue
        }
    }
}
