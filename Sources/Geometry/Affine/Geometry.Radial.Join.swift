#if Affine
    extension Geometry.Radial {

        /// How the points sampled on a radial curve are joined into a closed path.
        public enum Join {

            /// A straight line from each sample to the next, and from the last back to the first.
            case straight

            /// The smooth closed loop through the samples, `Geometry.Path.loop(through:)`.
            case smooth
        }
    }

    extension Geometry.Radial.Join: Sendable {}
    extension Geometry.Radial.Join: Equatable {}
    extension Geometry.Radial.Join: Hashable {}
#endif
