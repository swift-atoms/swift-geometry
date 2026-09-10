import Geometry
import Testing

@Suite
struct `Depth behavior before owner migration` {
    @Test
    func `Depth arithmetic preserves the represented scalar`() {
        typealias Depth = Geometry<Int, Void>.Depth
        let a = Depth(7)
        let b = Depth(3)
        #expect((a + b).value == 10)
        #expect((a - b).value == 4)
        #expect((-a).value == -7)
        #expect(b < a)
    }

    @Test
    func `Mapping visits the depth value once`() {
        var visits = 0
        let mapped = Geometry<Int, Void>.Depth(3).map { value in
            visits += 1
            return Double(value) / 2
        }
        let depth: Geometry<Double, Void>.Depth = mapped
        #expect(visits == 1)
        #expect(depth.value == 1.5)
    }
}
