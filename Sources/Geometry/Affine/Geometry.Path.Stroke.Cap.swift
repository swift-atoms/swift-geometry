#if Affine
    extension Geometry.Path.Stroke {

        public enum Cap: Sendable, Hashable, CaseIterable {

            case butt

            case round

            case square
        }
    }
#endif
