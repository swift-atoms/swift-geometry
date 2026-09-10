import Geometry
import Testing

@Test(arguments: Curvature.allCases)
func `Opposite curvature is an involution`(_ curvature: Curvature) {
    #expect(curvature.opposite != curvature)
    #expect(curvature.opposite.opposite == curvature)
    #expect(!curvature == curvature.opposite)
}

@Test
func `Current curvature representation distinguishes both cases`() {
    #expect(Set(Curvature.allCases) == [.convex, .concave])
}
