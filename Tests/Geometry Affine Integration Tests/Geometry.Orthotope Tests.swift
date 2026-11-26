#if Affine
    import Vector
    import Displacement
    import Scale
    import Quantizer
    @testable import Geometry
    import Testing

    enum `Geometry.Orthotope Tests` {}

    extension `Geometry.Orthotope Tests` {
        @Suite
        struct `Geometry.Orthotope - Integer corners` {
            @Test
            func `Even extents keep their corners`() throws {
                let rect = try #require(
                    Geometry<Int, Void>.Rectangle(llx: 1, lly: 2, urx: 7, ury: 12)
                )
                #expect(rect.center == Geometry<Int, Void>.Point(x: 4, y: 7))
                #expect(rect.halfExtents.width == 3)
                #expect(rect.halfExtents.height == 5)
            }

            @Test
            func `Odd width is refused`() {
                #expect(Geometry<Int, Void>.Rectangle(llx: 0, lly: 0, urx: 5, ury: 4) == nil)
            }

            @Test
            func `Odd height is refused`() {
                #expect(Geometry<Int, Void>.Rectangle(llx: 0, lly: 0, urx: 4, ury: 3) == nil)
            }

            @Test
            func `Origin and size form refuses odd extents`() {
                #expect(Geometry<Int, Void>.Rectangle(x: 0, y: 0, width: 4, height: 6) != nil)
                #expect(Geometry<Int, Void>.Rectangle(x: 0, y: 0, width: 3, height: 6) == nil)
            }
        }
    }

    extension `Geometry.Orthotope Tests` {
        @Suite
        struct `Geometry.Orthotope - Points at fractions` {
            private typealias Plane = Geometry<Double, Void>

            @Test
            func `A point at fractions of the extents runs from the least corner, and beyond it`() {
                let rect = Plane.Rectangle(llx: 10, lly: 20, urx: 50, ury: 120)
                #expect(rect.point(at: Scale(x: 0, y: 0)) == Plane.Point<2>([10, 20]))
                #expect(rect.point(at: Scale(x: 1, y: 1)) == Plane.Point<2>([50, 120]))
                #expect(rect.point(at: Scale(x: 0.5, y: 0.5)) == rect.center)
                #expect(rect.point(at: Scale(x: 0.25, y: 1.5)) == Plane.Point<2>([20, 170]))
                #expect(rect.point(at: Scale(x: -0.5, y: 0)) == Plane.Point<2>([-10, 20]))
            }
        }
    }
#endif
