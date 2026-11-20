#if Affine
    extension Geometry.Polyline {

        /// Whether a polyline connects its last point back to its first.
        public enum Closure: Sendable, Hashable {
            case open
            case closed
        }
    }
#endif
