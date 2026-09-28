#if Affine
public import Orthotope
public import Size
public import Vector
public import Magnitude
public import Tagged

extension Geometry.Orthotope where Scalar: Magnitude::Scalar {
    public init(_ box: Tagged<Space, Orthotope::Orthotope<N, Scalar>>) {
        self.init(center: Geometry.Point(.init(_unchecked: box.underlying.center)),
            halfExtents: Geometry.Size(box.underlying.halfExtents.values.components))
    }
    /// Reject negative or invalid extents through the canonical Size validation boundary.
    public func validated() throws(Size::Size<N, Scalar>.Error) -> Tagged<Space, Orthotope::Orthotope<N, Scalar>> {
        let extents = try Size::Size<N, Scalar>(validating: Vector::Vector(halfExtents.dimensions))
        return .init(_unchecked: Orthotope::Orthotope(center: center.position.underlying, halfExtents: extents))
    }
}
#endif
