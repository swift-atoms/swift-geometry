#if Boundary
import Affine
import Boundary
import Geometry
import Geometry_Boundary
import Tagged
import Testing

enum TestSpace {}

@Suite
struct `Geometry Boundary Tests` {

    typealias Plane = Geometry<Double, TestSpace>

    let rectangle = Plane.Rectangle(
        llx: Plane.X(_unchecked: -2),
        lly: Plane.Y(_unchecked: -3),
        urx: Plane.X(_unchecked: 5),
        ury: Plane.Y(_unchecked: 7)
    )

    @Test
    func `bottom corners use the lower y boundary`() {
        let left = rectangle.corner(.bottomLeft)
        let right = rectangle.corner(.bottomRight)

        #expect(left.x == rectangle.llx)
        #expect(left.y == rectangle.lly)
        #expect(right.x == rectangle.urx)
        #expect(right.y == rectangle.lly)
    }

    @Test
    func `top corners use the upper y boundary`() {
        let left = rectangle.corner(.topLeft)
        let right = rectangle.corner(.topRight)

        #expect(left.x == rectangle.llx)
        #expect(left.y == rectangle.ury)
        #expect(right.x == rectangle.urx)
        #expect(right.y == rectangle.ury)
    }
}
#endif
