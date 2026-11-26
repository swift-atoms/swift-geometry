#if Affine
    import Cardinal
    import Geometry
    import Testing
    import Vector

    @Suite
    struct `Geometry.Polyline Tests` {
        private typealias Plane = Geometry<Double, Void>

        @Test
        func `a point along a polyline is exact within its piece, and a prefix ends where the length does`() {
            let points = [Plane.Point<2>([0, 0]), Plane.Point<2>([4, 0]), Plane.Point<2>([4, 4])]
            #expect(Plane.Polyline.point(at: 6, along: points) == Plane.Point<2>([4, 2]))
            #expect(Plane.Polyline.point(atShare: 0.25, along: points) == Plane.Point<2>([2, 0]))
            #expect(Plane.Polyline.point(at: 99, along: points) == Plane.Point<2>([4, 4]))
            #expect(Plane.Polyline.point(at: -1, along: points) == Plane.Point<2>([0, 0]))
            #expect(Plane.Polyline.prefix(points, length: 5) == [Plane.Point<2>([0, 0]), Plane.Point<2>([4, 0]), Plane.Point<2>([4, 1])])
            #expect(Plane.Polyline.prefix(points, length: 0).isEmpty)
        }

        @Test
        func `a point along a polyline from a first point always has a value`() {
            let first = Plane.Point<2>([0, 0])
            let rest = [Plane.Point<2>([4, 0]), Plane.Point<2>([4, 4])]
            #expect(Plane.Polyline.point(at: 6, from: first, through: rest) == Plane.Point<2>([4, 2]))
            #expect(Plane.Polyline.point(atShare: 0.25, from: first, through: rest) == Plane.Point<2>([2, 0]))
            #expect(Plane.Polyline.point(atShare: 2, from: first, through: rest) == Plane.Point<2>([4, 4]))
            #expect(Plane.Polyline.point(atShare: 0.5, from: first, through: []) == first)
            #expect(Plane.Polyline.point(at: 3, from: first, through: []) == first)
        }

        @Test
        func `a ribbon goes out along one side and back along the other, as wide as asked`() {
            let points = [Plane.Point<2>([0, 0]), Plane.Point<2>([10, 0])]
            let outline = Plane.Polyline.ribbon(points) { along, total in along < total / 2 ? 1 : 2 }
            #expect(outline == [Plane.Point<2>([0, 1]), Plane.Point<2>([10, 2]), Plane.Point<2>([10, -2]), Plane.Point<2>([0, -1])])
            #expect(Plane.Polyline.ribbon([Plane.Point<2>([0, 0])]) { _, _ in 1 }.isEmpty)
        }

        @Test
        func `subdivided inserts intermediate points along open and closed polylines`() {
            let open = Plane.Polyline.subdivided(
                [Plane.Point<2>([0, 0]), Plane.Point<2>([10, 0])],
                closure: .open,
                step: 2.5
            )
            #expect(open.count == 5)
            #expect(open.first == Plane.Point<2>([0, 0]))
            #expect(open.last == Plane.Point<2>([10, 0]))

            let closed = Plane.Polyline.subdivided(
                [Plane.Point<2>([0, 0]), Plane.Point<2>([4, 0]), Plane.Point<2>([4, 4])],
                closure: .closed,
                step: 2
            )
            #expect(closed.count >= 6)
            #expect(closed.first == Plane.Point<2>([0, 0]))
        }

        @Test
        func `catmullRom interpolates endpoints for open spline and wraps for closed spline`() {
            let input = [
                Plane.Point<2>([0, 0]),
                Plane.Point<2>([10, 10]),
                Plane.Point<2>([20, 0]),
            ]
            let open = Plane.Polyline.catmullRom(input, closure: .open, step: 5)
            #expect(open.first == input.first)
            #expect(open.last == input.last)
            #expect(open.count > input.count)

            let closed = Plane.Polyline.catmullRom(input, closure: .closed, step: 5)
            #expect(closed.count > input.count)
        }

        @Test
        func `unit, normal, normals, and lengths compute Euclidean geometry`() {
            let v = Vector<2, Double>(x: 3, y: 4)
            let u = Plane.Polyline.unit(of: v)
            #expect(abs(u.x - 0.6) < 1e-12)
            #expect(abs(u.y - 0.8) < 1e-12)

            let n = Plane.Polyline.normal(of: v)
            #expect(abs(n.x + 0.8) < 1e-12)
            #expect(abs(n.y - 0.6) < 1e-12)
            #expect(Plane.Polyline.unit(of: .zero) == .zero)
            #expect(Plane.Polyline.normal(of: .zero) == .zero)

            let line = [Plane.Point<2>([0, 0]), Plane.Point<2>([3, 4]), Plane.Point<2>([3, 9])]
            let lengths = Plane.Polyline.lengths(of: line)
            #expect(lengths.count == 3)
            #expect(abs(lengths[0] - 0) < 1e-12)
            #expect(abs(lengths[1] - 5) < 1e-12)
            #expect(abs(lengths[2] - 10) < 1e-12)

            let normals = Plane.Polyline.normals(of: line)
            #expect(normals.count == 3)
            #expect(abs(normals[0].length - 1) < 1e-12)
        }

        @Test
        func `ellipse vertices samples evenly spaced perimeter points`() {
            let ellipse = Plane.Ellipse(
                center: Plane.Point<2>(x: 0, y: 0),
                semiMajor: 10,
                semiMinor: 5,
                rotation: .zero
            )
            let vertices = ellipse.vertices(count: Cardinal(4))
            #expect(vertices.count == 4)
            #expect(abs(vertices[0][0] - 10) < 1e-12)
            #expect(abs(vertices[0][1] - 0) < 1e-12)
            #expect(abs(vertices[1][0] - 0) < 1e-12)
            #expect(abs(vertices[1][1] - 5) < 1e-12)
            #expect(ellipse.vertices(count: .zero).isEmpty)
        }
    }
#endif
