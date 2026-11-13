#if Affine
    import Cardinal
    import Direction
    @testable import Geometry
    import Geometry_Test_Support
    import Numeric
    import Scale
    import Testing

    private typealias Geo = Geometry<Double, Void>

    private func at(_ x: Double, _ y: Double) -> Geo.Point<2> { .init([x, y]) }

    private func near(_ a: Geo.Point<2>, _ b: Geo.Point<2>, within tolerance: Double = 1e-12) -> Bool {
        abs(a[0] - b[0]) <= tolerance && abs(a[1] - b[1]) <= tolerance
    }

    @Suite
    struct `Geometry.Radial Tests` {
        @Test
        func `Samples lie at the radius in evenly spread directions, the first on the positive x axis`() {
            let wobble = Geo.Radial { angle in .init(2 + Double.cos(3 * angle.underlying)) }
            let center = at(1, -2)
            let corners = wobble.vertices(about: center, count: 12)
            #expect(corners.count == 12)
            #expect(near(corners[0], at(4, -2)))
            zip(corners.indices, corners).forEach { index, corner in
                let angle = 2 * Double.pi * Double(index) / 12
                let reach = 2 + Double.cos(3 * angle)
                #expect(near(corner, at(1 + reach * Double.cos(angle), -2 + reach * Double.sin(angle))))
            }
        }

        @Test
        func `A circle has its radius in every direction`() {
            let circle = Geo.Radial(radius: 3)
            for angle in [0.0, 0.4, 2.0, -5.0] {
                #expect(circle.radius(at: Radian(angle)) == 3)
            }
        }

        @Test
        func `A star's radial curve sampled at its corners gives the star's vertices`() throws {
            let star = try #require(Geo.Star(points: 5, outer: 2, inner: 0.7, at: at(3, 4)))
            let corners = Geo.Radial(star).vertices(about: at(3, 4), count: 10)
            zip(corners, star.vertices).forEach { sampled, vertex in
                #expect(near(sampled, vertex))
            }
        }

        @Test
        func `Mixing is the curve itself at 0, the other at 1, and linear in between and beyond`() throws {
            let star = try #require(Geo.Star(points: 4, outer: 2, inner: 1))
            let from = Geo.Radial(radius: 1)
            let to = Geo.Radial(star)
            for angle in [0.0, 0.3, 1.1, 4.0] {
                let r0 = from.radius(at: Radian(angle)).underlying
                let r1 = to.radius(at: Radian(angle)).underlying
                for t in [0.0, 0.25, 1.0, 1.5, -0.5] {
                    let mixed = from.mixed(to: to, at: Scale(t)).radius(at: Radian(angle)).underlying
                    #expect(abs(mixed - (r0 + t * (r1 - r0))) < 1e-12)
                }
                #expect(from.mixed(to: to, at: Scale(0)).radius(at: Radian(angle)).underlying == r0)
                #expect(from.mixed(to: to, at: Scale(1)).radius(at: Radian(angle)).underlying == r1)
            }
        }

        @Test
        func `A radial curve is Sendable, so a mixed one can cross into a task`() async {
            let mixed = Geo.Radial(radius: 1).mixed(to: Geo.Radial(radius: 3), at: Scale(0.5))
            let reach = await Task.detached { mixed.radius(at: Radian(1)).underlying }.value
            #expect(reach == 2)
        }

        @Test
        func `A path through the samples is straight or the smooth loop, and needs three samples`() throws {
            let circle = Geo.Radial(radius: 2)
            let center = at(0, 1)
            let corners = circle.vertices(about: center, count: 8)
            let straight = try #require(Geo.Path(circle, about: center, samples: 8))
            #expect(straight == Geo.Path.polygon(vertices: corners))
            let smooth = try #require(Geo.Path(circle, about: center, samples: 8, joined: .smooth))
            #expect(smooth == Geo.Path.loop(through: corners))
            #expect(smooth.contains(center, rule: .nonzero) && !smooth.contains(at(0, 3.5), rule: .nonzero))
            #expect(Geo.Path(circle, about: center, samples: 2) == nil)
            #expect(Geo.Path(circle, about: center, samples: 2, joined: .smooth) == nil)
        }
    }
#endif
