#if Affine
    public import Vector

    extension Geometry {

        /// Algorithms over sequences of points in a 2D coordinate space.
        public enum Polyline {}
    }

    extension Geometry.Polyline where Scalar: BinaryFloatingPoint {

        @inlinable
        static func catmullRomAxis(
            _ a: Scalar,
            _ b: Scalar,
            _ c: Scalar,
            _ d: Scalar,
            t: Scalar,
            t2: Scalar,
            t3: Scalar
        ) -> Scalar {
            let c0: Scalar = 2 * b
            let c1: Scalar = (-a + c) * t
            let c2: Scalar = (2 * a - 5 * b + 4 * c - d) * t2
            let c3: Scalar = (-a + 3 * b - 3 * c + d) * t3
            return (c0 + c1 + c2 + c3) / 2
        }

        /// Samples a Catmull-Rom spline through `points` with spacing `step`.
        @inlinable
        public static func catmullRom(
            _ points: [Geometry.Point<2>],
            closure: Closure,
            step: Scalar = 2.5
        ) -> [Geometry.Point<2>] {
            guard points.count >= 2 else { return points }
            var output: [Geometry.Point<2>] = []
            let count = points.count
            let last = points.index(before: points.endIndex)
            let segments = closure == .closed ? count : last
            func sample(_ index: Int) -> Geometry.Point<2> {
                if closure == .closed {
                    return points[((index % count) + count) % count]
                }
                return points[Swift.min(Swift.max(index, 0), last)]
            }
            (0..<segments).forEach { segment in
                let p0 = sample(segment - 1)
                let p1 = sample(segment)
                let p2 = sample(segment + 1)
                let p3 = sample(segment + 2)
                let dx = p2[0] - p1[0]
                let dy = p2[1] - p1[1]
                let distance = (dx * dx + dy * dy).squareRoot()
                let subdivisions = Swift.max(2, Int(distance / step))
                (0..<subdivisions).forEach { part in
                    let t = Scalar(part) / Scalar(subdivisions)
                    let t2 = t * t
                    let t3 = t2 * t
                    let x = catmullRomAxis(p0[0], p1[0], p2[0], p3[0], t: t, t2: t2, t3: t3)
                    let y = catmullRomAxis(p0[1], p1[1], p2[1], p3[1], t: t, t2: t2, t3: t3)
                    output.append(Geometry.Point<2>([x, y]))
                }
            }
            if closure == .open, let last = points.last {
                output.append(last)
            }
            return output
        }

        /// Linearly subdivides `points` so consecutive vertices are at most `step` apart.
        @inlinable
        public static func subdivided(
            _ points: [Geometry.Point<2>],
            closure: Closure,
            step: Scalar
        ) -> [Geometry.Point<2>] {
            guard !points.isEmpty else { return [] }
            var output: [Geometry.Point<2>] = []
            let count = points.count
            let last = points.index(before: points.endIndex)
            let segments = closure == .closed ? count : last
            (0..<Swift.max(0, segments)).forEach { segment in
                let start = points[segment]
                let end = points[(segment + 1) % count]
                let dx = end[0] - start[0]
                let dy = end[1] - start[1]
                let distance = (dx * dx + dy * dy).squareRoot()
                let subdivisions = Swift.max(1, Int(distance / step))
                (0..<subdivisions).forEach { part in
                    let fraction = Scalar(part) / Scalar(subdivisions)
                    output.append(Geometry.Point<2>([start[0] + dx * fraction, start[1] + dy * fraction]))
                }
            }
            if closure == .open, let last = points.last {
                output.append(last)
            }
            return output
        }

        /// The unit perpendicular vector `(-y, x) / |v|`, or zero when `vector` is degenerate.
        @inlinable
        public static func normal(of vector: Vector<2, Scalar>) -> Vector<2, Scalar> {
            let length = vector.length
            guard length > 1e-9 else { return .zero }
            return Vector<2, Scalar>(x: -vector.y / length, y: vector.x / length)
        }

        /// The unit direction vector `v / |v|`, or zero when `vector` is degenerate.
        @inlinable
        public static func unit(of vector: Vector<2, Scalar>) -> Vector<2, Scalar> {
            let length = vector.length
            guard length > 1e-9 else { return .zero }
            return vector.scaled(by: 1 / length)
        }

        /// Per-vertex unit normals estimated from central differences along `points`.
        @inlinable
        public static func normals(of points: [Geometry.Point<2>]) -> [Vector<2, Scalar>] {
            guard !points.isEmpty else { return [] }
            let last = points.endIndex - 1
            return points.indices.map { index in
                let next = points[Swift.min(index + 1, last)]
                let previous = points[Swift.max(index - 1, 0)]
                return normal(of: Vector<2, Scalar>(x: next[0] - previous[0], y: next[1] - previous[1]))
            }
        }

        /// Cumulative arc lengths along `points`, starting at zero.
        @inlinable
        public static func lengths(of points: [Geometry.Point<2>]) -> [Scalar] {
            guard !points.isEmpty else { return [] }
            var distances: [Scalar] = [0]
            distances.reserveCapacity(points.count)
            points.indices.dropFirst().forEach { index in
                let dx = points[index][0] - points[index - 1][0]
                let dy = points[index][1] - points[index - 1][1]
                distances.append(distances[index - 1] + (dx * dx + dy * dy).squareRoot())
            }
            return distances
        }
    }

    extension Geometry.Polyline where Scalar: BinaryFloatingPoint {

        /// The point at a length along `points`, measured over its straight pieces from the first point: exact
        /// within the piece it falls in, the first point at or before 0, the last at or beyond the whole length;
        /// nil for no points.
        @inlinable
        public static func point(at length: Scalar, along points: [Geometry.Point<2>]) -> Geometry.Point<2>? {
            guard let first = points.first else { return nil }
            guard length > 0 else { return first }
            var walked: Scalar = 0
            for index in points.indices.dropFirst() {
                let dx = points[index][0] - points[index - 1][0]
                let dy = points[index][1] - points[index - 1][1]
                let piece = (dx * dx + dy * dy).squareRoot()
                if piece > 0, walked + piece >= length {
                    let share = (length - walked) / piece
                    return Geometry.Point<2>([points[index - 1][0] + dx * share, points[index - 1][1] + dy * share])
                }
                walked += piece
            }
            return points.last
        }

        /// `point(at:along:)` at a share of the whole length, held to 0…1.
        @inlinable
        public static func point(atShare share: Scalar, along points: [Geometry.Point<2>]) -> Geometry.Point<2>? {
            let total = lengths(of: points).last ?? 0
            return point(at: Swift.min(Swift.max(share.isNaN ? 0 : share, 0), 1) * total, along: points)
        }

        /// The points of `points` up to a length along them, the last one cut exactly where the length ends within
        /// its piece: a line drawn on as far as a pen has gone. Empty for no points or a length that is not positive.
        @inlinable
        public static func prefix(_ points: [Geometry.Point<2>], length: Scalar) -> [Geometry.Point<2>] {
            guard let first = points.first, length > 0 else { return [] }
            var kept = [first]
            var walked: Scalar = 0
            for index in points.indices.dropFirst() {
                let dx = points[index][0] - points[index - 1][0]
                let dy = points[index][1] - points[index - 1][1]
                let piece = (dx * dx + dy * dy).squareRoot()
                if walked + piece >= length {
                    let share = piece > 0 ? (length - walked) / piece : 0
                    kept.append(Geometry.Point<2>([points[index - 1][0] + dx * share, points[index - 1][1] + dy * share]))
                    return kept
                }
                kept.append(points[index])
                walked += piece
            }
            return kept
        }
    }
#endif
