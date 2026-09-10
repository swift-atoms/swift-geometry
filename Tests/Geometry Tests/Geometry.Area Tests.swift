import Geometry
import Testing

@Test
func `Geometry area reuses its current linear owner without conversion`() {
    enum Drawing {}
    let linear = Linear<Int, Drawing>.Area(_unchecked: 6)
    let geometry: Geometry<Int, Drawing>.Area = linear
    let roundTrip: Linear<Int, Drawing>.Area = geometry
    #expect(roundTrip == linear)
}
