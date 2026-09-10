public import Inset

extension Geometry {
    /// The canonical signed inset value. Frame interpretation belongs to the
    /// consuming domain; this alias does not add storage or a phantom frame.
    public typealias Insets = Inset<2, Scalar>
}
