#if Affine
    extension Geometry.Ellipse.Arc {

        public enum Extent: Sendable, Hashable, CaseIterable {

            case minor

            case major
        }
    }
#endif
