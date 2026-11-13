#if Affine
    @testable import Geometry
    import Testing

    private typealias Plane = Geometry<Double, Void>

    private func point(_ x: Double, _ y: Double) -> Plane.Point<2> { Plane.Point<2>([x, y]) }

    private func close(_ a: Double, _ b: Double, _ tolerance: Double = 1e-9) -> Bool { abs(a - b) <= tolerance }

    private let disc = Plane.Region.ball(Plane.Circle(center: point(0, 0), radius: .init(10)))
    private let box = Plane.Rectangle(llx: .init(-20), lly: .init(-10), urx: .init(20), ury: .init(10))

    enum `Geometry.Region Tests` {}

    extension `Geometry.Region Tests` {
        @Suite
        struct `Geometry.Region - Distance` {
            @Test
            func `A disc's distance is the distance from its centre less its radius, and its gradient points away`() {
                let sample = disc.sample(at: point(13, 4))
                #expect(close(sample.distance, (169.0 + 16).squareRoot() - 10))
                #expect(close(sample.gradient[0], 13 / (185.0).squareRoot()))
                #expect(close(sample.gradient[1], 4 / (185.0).squareRoot()))
                #expect(disc.distance(to: point(0, 0)) == -10)
                #expect(disc.sample(at: point(0, 0)).gradient == .zero)
            }

            @Test
            func `A rounded rectangle is a plain rectangle without a radius and a capsule at half its shorter side`() {
                let plain = Plane.Region.rectangle(box, radius: 0)
                #expect(close(plain.distance(to: point(25, 0)), 5))
                #expect(close(plain.distance(to: point(0, 7)), -3))
                #expect(close(plain.distance(to: point(23, 14)), 5))
                let capsule = Plane.Region.capsule(box)
                #expect(capsule == .rectangle(box, radius: 10))
                #expect(close(capsule.distance(to: point(10 + 6, 8)), 0))
                #expect(close(capsule.distance(to: point(-10, 0)), -10))
                let held = Plane.Region.rectangle(box, radius: 1000)
                #expect(held.distance(to: point(31, 3)) == capsule.distance(to: point(31, 3)))
            }

            @Test
            func `The gradient is the distance's rate of change`() {
                let regions: [Plane.Region] = [disc, .rectangle(box, radius: 6), .capsule(box)]
                let step = 1e-6
                for region in regions {
                    for (x, y) in [(13.0, 4.0), (19.0, 9.5), (-3.0, 2.0), (25.0, -14.0), (2.0, -9.0)] {
                        let sample = region.sample(at: point(x, y))
                        let dx = (region.distance(to: point(x + step, y)) - region.distance(to: point(x - step, y))) / (2 * step)
                        let dy = (region.distance(to: point(x, y + step)) - region.distance(to: point(x, y - step))) / (2 * step)
                        #expect(close(sample.gradient[0], dx, 1e-5))
                        #expect(close(sample.gradient[1], dy, 1e-5))
                    }
                }
            }

            @Test
            func `A path's distance is the distance to its nearest side, negative inside under the nonzero rule`() throws {
                let square = Plane.Path(subpaths: [
                    .init(
                        startPoint: point(-20, -10),
                        segments: [
                            .line(.init(start: point(-20, -10), end: point(20, -10))),
                            .line(.init(start: point(20, -10), end: point(20, 10))),
                            .line(.init(start: point(20, 10), end: point(-20, 10))),
                        ],
                        isClosed: true
                    )
                ])
                let region = try Plane.Region(square, tolerance: .init(0.1))
                let plain = Plane.Region.rectangle(box, radius: 0)
                for (x, y) in [(25.0, 0.0), (0.0, 7.0), (23.0, 14.0), (-19.0, 3.0)] {
                    let a = region.sample(at: point(x, y))
                    let b = plain.sample(at: point(x, y))
                    #expect(close(a.distance, b.distance))
                    #expect(close(a.gradient[0], b.gradient[0]))
                    #expect(close(a.gradient[1], b.gradient[1]))
                }
            }
        }

        @Suite
        struct `Geometry.Region - Union` {
            static let left = Plane.Region.ball(Plane.Circle(center: point(-15, 0), radius: .init(10)))
            static let right = Plane.Region.ball(Plane.Circle(center: point(15, 0), radius: .init(10)))

            @Test
            func `Far from the neck the smooth union is the plain union, bit for bit`() {
                let joined = Plane.Region.union([Self.left, Self.right], radius: 6)
                for (x, y) in [(-30.0, 0.0), (-15.0, 12.0), (28.0, -3.0), (15.0, 0.0)] {
                    let a = Self.left.sample(at: point(x, y))
                    let b = Self.right.sample(at: point(x, y))
                    #expect(joined.sample(at: point(x, y)) == (a.distance <= b.distance ? a : b))
                }
            }

            @Test
            func `The neck fills the gap: never above the plain union and at most a quarter of the radius below it`() {
                let joined = Plane.Region.union([Self.left, Self.right], radius: 24)
                #expect(joined.distance(to: point(0, 0)) == -1)
                #expect(Plane.Region.union([Self.left, Self.right], radius: 0).distance(to: point(0, 0)) == 5)
                for x in stride(from: -30.0, through: 30, by: 1.5) {
                    for y in stride(from: -15.0, through: 15, by: 1.5) {
                        let plain = Swift.min(Self.left.distance(to: point(x, y)), Self.right.distance(to: point(x, y)))
                        let smooth = joined.distance(to: point(x, y))
                        #expect(smooth <= plain)
                        #expect(smooth >= plain - 6 - 1e-12)
                    }
                }
            }

            @Test
            func `The union changes continuously with its parts and its radius`() {
                func neck(_ gap: Double, _ radius: Double) -> Double {
                    let a = Plane.Region.ball(Plane.Circle(center: point(-10 - gap / 2, 0), radius: .init(10)))
                    let b = Plane.Region.ball(Plane.Circle(center: point(10 + gap / 2, 0), radius: .init(10)))
                    return Plane.Region.union([a, b], radius: radius).distance(to: point(0, 3))
                }
                var gap = 20.0
                while gap > -5 {
                    #expect(abs(neck(gap, 8) - neck(gap - 0.01, 8)) < 0.02)
                    #expect(abs(neck(gap, 8) - neck(gap, 8.01)) < 0.02)
                    gap -= 0.5
                }
            }

            @Test
            func `The bounding box holds every point the region holds`() throws {
                let joined = Plane.Region.union([Self.left, Self.right], radius: 12)
                let rectangle = try #require(joined.boundingBox)
                #expect(rectangle.llx.underlying == -28)
                #expect(rectangle.urx.underlying == 28)
                #expect(rectangle.lly.underlying == -13)
                #expect(Plane.Region.union([], radius: 1).boundingBox == nil)
            }
        }
    }
#endif
