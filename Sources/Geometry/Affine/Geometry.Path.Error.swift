#if Affine
    extension Geometry.Path {

        public enum Error: Swift::Error, Sendable, Hashable {

            /// The flattening tolerance is not a positive finite length.
            case tolerance

            /// The stroke width is negative or not finite.
            case width

            /// The miter limit is below 1 or not finite.
            case limit
        }
    }
#endif
