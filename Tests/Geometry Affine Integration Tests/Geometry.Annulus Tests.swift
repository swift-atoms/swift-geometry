#if Affine
    import Foundation
    import Geometry
    import Testing

    private typealias Geo = Geometry<Double, Void>

    private func at(_ x: Double, _ y: Double) -> Geo.Point<2> { .init([x, y]) }

    @Suite
    struct `Geometry.Annulus Tests` {
        @Test
        func `An annulus holds an inner radius from zero to its outer radius`() throws {
            #expect(Geo.Annulus(center: at(0, 0), inner: 2, outer: 5) != nil)
            #expect(Geo.Annulus(center: at(0, 0), inner: 0, outer: 5) != nil)
            #expect(Geo.Annulus(center: at(0, 0), inner: 3, outer: 3) != nil)
            #expect(Geo.Annulus(center: at(0, 0), inner: 6, outer: 5) == nil)
            #expect(Geo.Annulus(center: at(0, 0), inner: -1, outer: 5) == nil)
        }

        @Test
        func `A band about a middle radius has that radius and width`() throws {
            let band = try #require(Geo.Annulus(center: at(1, 2), radius: 10, width: 4))
            #expect(band.inner == 8)
            #expect(band.outer == 12)
            #expect(band.radius == 10)
            #expect(band.width == 4)
            #expect(band.outerCircle == Geo.Circle(center: at(1, 2), radius: 12))
            #expect(band.innerCircle == Geo.Circle(center: at(1, 2), radius: 8))
            #expect(Geo.Annulus(center: at(0, 0), radius: 1, width: 3) == nil)
            #expect(Geo.Annulus(center: at(0, 0), radius: 1, width: -1) == nil)
        }

        @Test
        func `An annulus holds the points between its circles, both edges included`() throws {
            let ring = try #require(Geo.Annulus(center: at(0, 0), inner: 2, outer: 5))
            #expect(ring.contains(at(3, 0)))
            #expect(ring.contains(at(0, 2)))
            #expect(ring.contains(at(-5, 0)))
            #expect(!ring.contains(at(1, 1)))
            #expect(!ring.contains(at(4, 4)))
            #expect(!ring.contains(at(0, 0)))
        }

        @Test
        func `An annulus's area is the outer disc's less the hole's`() throws {
            let ring = try #require(Geo.Annulus(center: at(0, 0), inner: 2, outer: 5))
            #expect(abs(ring.area.underlying - Double.pi * 21) < 1e-12)
        }

        @Test
        func `An annulus decodes only an inner radius from zero to its outer radius`() throws {
            let ring = try #require(Geo.Annulus(center: at(1, 2), inner: 2, outer: 5))
            let data = try JSONEncoder().encode(ring)
            #expect(try JSONDecoder().decode(Geo.Annulus.self, from: data) == ring)
            var object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
            (object["inner"], object["outer"]) = (object["outer"], object["inner"])
            let swapped = try JSONSerialization.data(withJSONObject: object)
            #expect(throws: DecodingError.self) { try JSONDecoder().decode(Geo.Annulus.self, from: swapped) }
        }
    }
#endif
