#if Affine
    public import Scale

    extension Geometry.Path.Stroke {

        public enum Join {

            case miter(limit: Scale<1, Scalar>)

            case round

            case bevel
        }
    }

    extension Geometry.Path.Stroke.Join: Sendable where Scalar: Sendable {}
    extension Geometry.Path.Stroke.Join: Equatable where Scalar: Equatable {}
    extension Geometry.Path.Stroke.Join: Hashable where Scalar: Hashable {}
#endif
