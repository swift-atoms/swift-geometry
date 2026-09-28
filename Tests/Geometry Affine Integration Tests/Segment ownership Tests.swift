#if Affine
import Vector
import Displacement
import Scale
import Quantizer
import Geometry
import Segment
import Testing

private enum Drawing {}
private typealias Geo = Geometry<Double, Drawing>

@Test
func `Geometry segment aliases preserve the atom type without conversion`() {
    let atom: Segment<Geo.Point<2>> = .init(
        start: .init(x: 1, y: 2), end: .init(x: 3, y: 4)
    )
    let nested: Geo.Line.Segment = atom
    let convenience: Geo.LineSegment = nested
    let roundTrip: Segment<Geo.Point<2>> = convenience
    #expect(roundTrip == atom)
    #expect(roundTrip.reversed.start == atom.end)
}

@Test
func `Scalar conversion composes endpoint mapping rather than redefining segment mapping`() {
    let segment: Geo.Line.Segment = .init(
        start: .init(x: 1, y: 2), end: .init(x: 3, y: 4)
    )
    var visits = 0
    let mapped = segment.map { point in
        visits += 1
        return point.map { Float($0) }
    }
    let result: Segment<Geometry<Float, Drawing>.Point<2>> = mapped
    #expect(visits == 2)
    #expect(result.start.x == 1)
    #expect(result.end.y == 4)
}
#endif
