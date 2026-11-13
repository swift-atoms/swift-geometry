#if Affine
    import Cardinal
    import Direction
    import Foundation
    @testable import Geometry
    import Geometry_Test_Support
    import Numeric
    import Testing

    private typealias Geo = Geometry<Double, Void>

    private func at(_ x: Double, _ y: Double) -> Geo.Point<2> { .init([x, y]) }

    @Suite
    struct `Geometry.Star Tests` {
        @Test
        func `The edge is the outer radius toward a point and the inner toward a notch`() throws {
            let star = try #require(Geo.Star(points: 5, outer: 2, inner: 0.8))
            (0..<10).forEach { index in
                let angle = Radian<Double>(Double.pi * Double(index) / 5)
                let expected = index.isMultiple(of: 2) ? 2.0 : 0.8
                #expect(abs(star.radius(at: angle).underlying - expected) < 1e-12)
            }
        }

        @Test
        func `The edge lies on the straight line between a point and its notch`() throws {
            let star = try #require(Geo.Star(points: 6, outer: 1, inner: 0.6))
            let corners = star.vertices
            (1..<20).forEach { step in
                let angle = Double.pi / 6 * Double(step) / 20
                let reach = star.radius(at: Radian(angle)).underlying
                let (x, y) = (reach * Double.cos(angle), reach * Double.sin(angle))
                let (a, b) = (corners[0], corners[1])
                let cross = (b[0] - a[0]) * (y - a[1]) - (b[1] - a[1]) * (x - a[0])
                #expect(abs(cross) < 1e-12)
            }
        }

        @Test
        func `The edge repeats with each point and mirrors about it`() throws {
            let star = try #require(Geo.Star(points: 3, outer: 1, inner: 0.5))
            for angle in [0.1, 0.7, 1.3, -0.4, 9.0] {
                let here = star.radius(at: Radian(angle)).underlying
                #expect(abs(here - star.radius(at: Radian(angle + 2 * Double.pi / 3)).underlying) < 1e-12)
                #expect(abs(here - star.radius(at: Radian(-angle)).underlying) < 1e-12)
            }
        }

        @Test
        func `With the inner radius at the polygon's inradius the star is the regular polygon`() throws {
            let square = try #require(Geo.Star(points: 4, outer: 1, inner: .init(Double.cos(Double.pi / 4))))
            for angle in stride(from: 0.0, through: 1.5, by: 0.1) {
                let reach = square.radius(at: Radian(angle)).underlying
                #expect(abs(reach * Double.cos(angle - Double.pi / 4) - Double.cos(Double.pi / 4)) < 1e-12)
            }
        }

        @Test
        func `A star has twice as many corners as points, and is a closed path through them`() throws {
            let star = try #require(Geo.Star(points: 4, outer: 2, inner: 1, at: at(1, -1)))
            let corners = star.vertices
            #expect(corners.count == 8)
            #expect(abs(corners[0][0] - 3) < 1e-12 && abs(corners[0][1] + 1) < 1e-12)
            let path = Geo.Path(star)
            #expect(path.subpaths.count == 1 && path.subpaths[0].isClosed && path.subpaths[0].segments.count == 8)
            #expect(path.subpaths[0].startPoint == corners[0])
            #expect(path.subpaths[0].segments.last?.endPoint == corners[0])
            #expect(path.contains(at(1, -1), rule: .nonzero))
            #expect(path.contains(at(2.9, -1), rule: .nonzero) && !path.contains(at(2.2, 0.2), rule: .nonzero))
            #expect(Geo.Star(points: 1, outer: 1, inner: 1) == nil)
        }

        @Test
        func `A star round-trips through its encoding, and fewer than two points fail to decode`() throws {
            let star = try #require(Geo.Star(points: 7, outer: 3, inner: 1.5, at: at(2, 5)))
            let data = try JSONEncoder().encode(star)
            #expect(try JSONDecoder().decode(Geo.Star.self, from: data) == star)
            let one = Data(#"{"center":[0,0],"points":1,"outer":1,"inner":0.5}"#.utf8)
            #expect(throws: DecodingError.self) { try JSONDecoder().decode(Geo.Star.self, from: one) }
        }
    }
#endif
