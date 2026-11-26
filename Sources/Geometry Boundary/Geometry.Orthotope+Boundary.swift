#if Boundary
public import Boundary
public import Geometry

extension Geometry.Orthotope where N == 2, Scalar: FloatingPoint {

    @inlinable
    public func corner(_ corner: Boundary.Corner) -> Geometry.Point<2> {
        switch corner {
        case .bottomLeft:
            return Geometry.Point(x: llx, y: lly)

        case .bottomRight:
            return Geometry.Point(x: urx, y: lly)

        case .topLeft:
            return Geometry.Point(x: llx, y: ury)

        case .topRight:
            return Geometry.Point(x: urx, y: ury)
        }
    }
}
#endif
