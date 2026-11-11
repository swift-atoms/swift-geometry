#if Affine
    extension Geometry.Path {

        public struct Stroke {

            public var width: Geometry.Length

            public var join: Join

            public var cap: Cap

            @inlinable
            public init(width: Geometry.Length, join: Join, cap: Cap) {
                self.width = width
                self.join = join
                self.cap = cap
            }
        }
    }

    extension Geometry.Path.Stroke: Sendable where Scalar: Sendable {}
    extension Geometry.Path.Stroke: Equatable where Scalar: Equatable {}
    extension Geometry.Path.Stroke: Hashable where Scalar: Hashable {}
#endif
