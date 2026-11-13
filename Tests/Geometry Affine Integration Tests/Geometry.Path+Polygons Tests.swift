#if Affine
    import Direction
    @testable import Geometry
    import Geometry_Test_Support
    import Testing

    private typealias Geo = Geometry<Double, Void>

    private func at(_ x: Double, _ y: Double) -> Geo.Point<2> { .init([x, y]) }

    private func square(_ low: Double, _ high: Double, clockwise: Bool = false) -> Geo.Polygon {
        let corners = [at(low, low), at(high, low), at(high, high), at(low, high)]
        return Geo.Polygon(vertices: clockwise ? corners.reversed() : corners)
    }

    /// The corners a closed subpath of lines runs through, as a polygon.
    private func corners(_ subpath: Geo.Path.Subpath) -> Geo.Polygon {
        Geo.Polygon(vertices: [subpath.startPoint] + subpath.segments.compactMap(\.endPoint))
    }

    @Suite
    struct `Geometry.Path+Polygons Tests` {
        @Test
        func `Each polygon is a closed subpath, in order, as polygon(vertices:) makes it`() throws {
            let first = square(0, 1)
            let second = square(2, 3, clockwise: true)
            let path = Geo.Path([first, second])
            #expect(path.subpaths.count == 2)
            #expect(path.subpaths[0] == Geo.Path.polygon(vertices: first.vertices)?.subpaths[0])
            #expect(path.subpaths[1] == Geo.Path.polygon(vertices: second.vertices)?.subpaths[0])
        }

        @Test
        func `A polygon of fewer than three vertices adds no subpath`() {
            let path = Geo.Path([Geo.Polygon(vertices: [at(0, 0), at(1, 1)]), Geo.Polygon(vertices: []), square(0, 1)])
            #expect(path.subpaths.count == 1)
        }

        @Test
        func `With a winding every subpath runs that way from the polygon's own first vertex`() {
            let polygons = [square(0, 2), square(1, 3, clockwise: true), square(5, 6, clockwise: true)]
            let counterclockwise = Geo.Path(polygons, winding: .counterclockwise)
            #expect(counterclockwise.subpaths.allSatisfy { corners($0).isCounterClockwise })
            let clockwise = Geo.Path(polygons, winding: .clockwise)
            #expect(clockwise.subpaths.allSatisfy { corners($0).isClockwise })
            zip(polygons, counterclockwise.subpaths).forEach { polygon, subpath in
                #expect(subpath.startPoint == polygon.vertices[0])
                #expect(corners(subpath).area == polygon.area)
            }
        }

        @Test
        func `Under nonzero the normalised path fills the union of overlapping polygons`() {
            let polygons = [square(0, 2), square(1, 3, clockwise: true)]
            let union = Geo.Path(polygons, winding: .counterclockwise)
            let raw = Geo.Path(polygons)
            let overlap = at(1.5, 1.5)
            for point in [overlap, at(0.5, 0.5), at(2.5, 2.5)] {
                #expect(union.contains(point, rule: .nonzero))
            }
            #expect(!union.contains(at(2.5, 0.5), rule: .nonzero))
            #expect(!raw.contains(overlap, rule: .nonzero))
            #expect(!union.contains(overlap, rule: .evenodd))
        }

        @Test
        func `A polygon of zero area is left as it is`() {
            let flat = Geo.Polygon(vertices: [at(0, 0), at(1, 0), at(2, 0)])
            #expect(Geo.Path([flat], winding: .clockwise) == Geo.Path([flat]))
        }

        @Test
        func `A bounding box culls: it meets a rectangle it overlaps or touches, not one apart from it`() throws {
            let triangle = Geo.Polygon(vertices: [at(0, 0), at(4, 0), at(0, 4)])
            let box = try #require(triangle.boundingBox)
            #expect(box.intersects(Geo.Rectangle(llx: 3, lly: 3, urx: 5, ury: 5)))
            #expect(box.intersects(Geo.Rectangle(llx: 4, lly: 4, urx: 5, ury: 5)))
            #expect(!box.intersects(Geo.Rectangle(llx: 4.5, lly: 0, urx: 5, ury: 1)))
            let path = try #require(Geo.Path([triangle]).boundingBox)
            #expect(path.intersects(Geo.Rectangle(llx: 3, lly: 3, urx: 5, ury: 5)))
        }
    }
#endif
