#if Affine
    public import Matrix
    public import Affine
    public import Displacement
    import Point
    public import Vector
    public import Tagged
    public import Scale
    public import Angle
    import Trigonometry

    public import Space
    public import Linear
    public import Numeric

    extension Geometry {

        public struct Bezier {

            public var controlPoints: [Point<2>]

            @inlinable
            public init(controlPoints: consuming [Point<2>]) {
                self.controlPoints = controlPoints
            }
        }
    }

    extension Geometry.Bezier: Sendable where Scalar: Sendable {}

    extension Geometry.Bezier {

        public struct Segment {

            public let start: Geometry.Point<2>

            public let control1: Geometry.Point<2>

            public let control2: Geometry.Point<2>

            public let end: Geometry.Point<2>

            @inlinable
            public init(
                start: Geometry.Point<2>,
                control1: Geometry.Point<2>,
                control2: Geometry.Point<2>,
                end: Geometry.Point<2>
            ) {
                self.start = start
                self.control1 = control1
                self.control2 = control2
                self.end = end
            }
        }
    }

    extension Geometry.Bezier.Segment: Sendable where Scalar: Sendable {}
    extension Geometry.Bezier: Equatable where Scalar: Equatable {}
    extension Geometry.Bezier: Hashable where Scalar: Hashable {}

    #if !hasFeature(Embedded)
        extension Geometry.Bezier: Codable where Scalar: Codable {}
    #endif

    extension Geometry.Bezier {

        @inlinable

        public var degree: Int { max(0, controlPoints.count - 1) }

        @inlinable
        public var isValid: Bool { controlPoints.count >= 2 }

        @inlinable
        public var startPoint: Geometry.Point<2>? { controlPoints.first }

        @inlinable
        public var endPoint: Geometry.Point<2>? { controlPoints.last }
    }

    extension Geometry.Bezier {

        @inlinable
        public static func linear(
            from start: Geometry.Point<2>,
            to end: Geometry.Point<2>
        ) -> Self {
            Self(controlPoints: [start, end])
        }

        @inlinable
        public static func quadratic(
            from start: Geometry.Point<2>,
            control: Geometry.Point<2>,
            to end: Geometry.Point<2>
        ) -> Self {
            Self(controlPoints: [start, control, end])
        }

        @inlinable
        public static func cubic(
            from start: Geometry.Point<2>,
            control1: Geometry.Point<2>,
            control2: Geometry.Point<2>,
            to end: Geometry.Point<2>
        ) -> Self {
            Self(controlPoints: [start, control1, control2, end])
        }
    }

    extension Geometry.Bezier where Scalar: FloatingPoint {

        @inlinable
        public func point(at t: Scale<1, Scalar>) -> Geometry.Point<2>? {
            Geometry.point(of: self, at: t)
        }

        @inlinable
        public func derivative(at t: Scale<1, Scalar>) -> Geometry.Vector<2>? {
            Geometry.derivative(of: self, at: t)
        }

        @inlinable
        public func tangent(at t: Scale<1, Scalar>) -> Geometry.Vector<2>? {
            guard let d = derivative(at: t) else { return nil }
            let normalized = Linear<Scalar, Space>.Vector.normalized(d)
            guard normalized.length.underlying > 0 else { return nil }
            return normalized
        }

        @inlinable
        public func normal(at t: Scale<1, Scalar>) -> Geometry.Vector<2>? {
            guard let tang = tangent(at: t) else { return nil }

            return Geometry.Vector(
                dx: Linear<Scalar, Space>.Dx(-tang.dy.underlying),
                dy: Linear<Scalar, Space>.Dy(tang.dx.underlying)
            )
        }
    }

    extension Geometry.Bezier where Scalar: FloatingPoint {

        @inlinable
        public func split(at t: Scale<1, Scalar>) -> (left: Self, right: Self)? {
            guard isValid else { return nil }

            var leftPoints: [Geometry.Point<2>] = []
            var rightPoints: [Geometry.Point<2>] = []

            leftPoints.reserveCapacity(controlPoints.count)
            rightPoints.reserveCapacity(controlPoints.count)

            var points = controlPoints
            guard let firstPoint = points.first, let lastPoint = points.last else { return nil }
            leftPoints.append(firstPoint)
            rightPoints.insert(lastPoint, at: 0)

            while points.count > 1 {
                var next: [Geometry.Point<2>] = []
                next.reserveCapacity(points.dropLast().count)
                for i in points.indices.dropLast() {
                    let p = points[i].lerp(to: points[i + 1], t: t)
                    next.append(p)
                }
                guard let nextFirst = next.first, let nextLast = next.last else { return nil }
                leftPoints.append(nextFirst)
                rightPoints.insert(nextLast, at: 0)
                points = next
            }

            return (Self(controlPoints: leftPoints), Self(controlPoints: rightPoints))
        }

        @inlinable
        public func subdivide(into segments: Int) -> [Geometry.Point<2>] {
            .init(subdividing: self, into: segments)
        }
    }

    extension Array {

        @inlinable
        public init<Scalar: FloatingPoint, Space>(
            subdividing bezier: Geometry<Scalar, Space>.Bezier,
            into segments: Int
        ) where Element == Geometry<Scalar, Space>.Point<2> {
            guard segments > 0 else {
                self = []
                return
            }

            var points: [Geometry<Scalar, Space>.Point<2>] = []
            points.reserveCapacity(segments + 1)

            (0...segments).forEach { i in
                let t: Scale<1, Scalar> = .init(Scalar(i) / Scalar(segments))
                if let p = bezier.point(at: t) {
                    points.append(p)
                }
            }

            self = points
        }
    }

    extension Geometry.Bezier where Scalar: FloatingPoint {

        @inlinable
        public var boundingBoxConservative: Geometry.Rectangle? {
            guard let first = controlPoints.first else { return nil }

            var minX = first.x
            var maxX = first.x
            var minY = first.y
            var maxY = first.y

            for point in controlPoints.dropFirst() {
                minX = .min(minX, point.x)
                maxX = .max(maxX, point.x)
                minY = .min(minY, point.y)
                maxY = .max(maxY, point.y)
            }

            return Geometry.Rectangle(
                llx: minX,
                lly: minY,
                urx: maxX,
                ury: maxY
            )
        }
    }

    extension Geometry.Bezier where Scalar: FloatingPoint {

        @inlinable
        public func length(segments: Int = 100) -> Geometry.ArcLength {
            let points = subdivide(into: segments)
            guard points.count >= 2 else { return .zero }

            var len: Geometry.Length = .zero
            for i in points.indices.dropLast() {
                len += points[i].distance(to: points[i + 1])
            }
            return len
        }
    }

    extension Geometry.Bezier where Scalar: FloatingPoint {

        @inlinable
        public func translated<Failure: Swift::Error>(
            by vector: Geometry.Vector<2>,
            using relationship: Affine<Geometry.Point<2>, Displacement::Displacement<2, Scalar>, Failure>
        ) throws(Failure) -> Self {
            let offset = Displacement::Displacement<2, Scalar>(components: Vector::Vector(vector.components))
            var result: [Geometry.Point<2>] = []
            for point in controlPoints { result.append(try relationship.translated(point, by: offset)) }
            return Self(controlPoints: result)
        }

        @inlinable
        public func scaled(by factor: Scale<1, Scalar>) -> Self? {
            guard let start = startPoint else { return nil }
            return scaled(by: factor, about: start)
        }

        @inlinable
        public func scaled(by factor: Scale<1, Scalar>, about point: Geometry.Point<2>) -> Self {
            Self(
                controlPoints: controlPoints.map { p in
                    Geometry.Point(
                        x: point.x + factor * (p.x - point.x),
                        y: point.y + factor * (p.y - point.y)
                    )
                }
            )
        }

        @inlinable
        public var reversed: Self {
            Self(controlPoints: controlPoints.reversed())
        }
    }

    extension Geometry.Bezier where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        @inlinable
        public static func approximating(_ ellipse: Geometry.Ellipse) -> [Self] {

            let k: Scalar = Scalar(0.5522847498307936)

            let cx: Scalar = ellipse.center.x.underlying
            let cy: Scalar = ellipse.center.y.underlying
            let a: Scalar = ellipse.semiMajor.underlying
            let b: Scalar = ellipse.semiMinor.underlying
            let cosR: Scalar = ellipse.rotation.cos.value
            let sinR: Scalar = ellipse.rotation.sin.value

            func rotated(x: Scalar, y: Scalar) -> Geometry.Point<2> {
                let rx: Scalar = x * cosR - y * sinR
                let ry: Scalar = x * sinR + y * cosR
                return Geometry.Point(
                    x: Geometry.X(cx + rx),
                    y: Geometry.Y(cy + ry)
                )
            }

            let right = rotated(x: a, y: Scalar(0))
            let top = rotated(x: Scalar(0), y: b)
            let left = rotated(x: -a, y: Scalar(0))
            let bottom = rotated(x: Scalar(0), y: -b)

            let ka: Scalar = k * a
            let kb: Scalar = k * b

            let c1Control1 = rotated(x: a, y: kb)
            let c1Control2 = rotated(x: ka, y: b)

            let c2Control1 = rotated(x: -ka, y: b)
            let c2Control2 = rotated(x: -a, y: kb)

            let c3Control1 = rotated(x: -a, y: -kb)
            let c3Control2 = rotated(x: -ka, y: -b)

            let c4Control1 = rotated(x: ka, y: -b)
            let c4Control2 = rotated(x: a, y: -kb)

            return [
                .cubic(from: right, control1: c1Control1, control2: c1Control2, to: top),
                .cubic(from: top, control1: c2Control1, control2: c2Control2, to: left),
                .cubic(from: left, control1: c3Control1, control2: c3Control2, to: bottom),
                .cubic(from: bottom, control1: c4Control1, control2: c4Control2, to: right),
            ]
        }

        @inlinable
        public static func approximating(_ circle: Geometry.Circle) -> [Self] {
            approximating(Geometry.Ellipse(circle))
        }
    }

    extension Geometry where Scalar: FloatingPoint {

        @inlinable
        public static func point(of bezier: Bezier, at t: Scale<1, Scalar>) -> Point<2>? {
            guard bezier.isValid else { return nil }

            var points = bezier.controlPoints
            while points.count > 1 {
                var next: [Point<2>] = []
                next.reserveCapacity(points.dropLast().count)
                for i in points.indices.dropLast() {
                    let p = points[i].lerp(to: points[i + 1], t: t)
                    next.append(p)
                }
                points = next
            }
            return points.first
        }

        @inlinable
        public static func derivative(of bezier: Bezier, at t: Scale<1, Scalar>) -> Vector<2>? {
            guard bezier.controlPoints.count >= 2 else { return nil }

            let n = Scalar(bezier.controlPoints.count - 1)

            var derivPoints: [Point<2>] = []
            derivPoints.reserveCapacity(bezier.controlPoints.dropLast().count)
            for i in bezier.controlPoints.indices.dropLast() {
                let dx = bezier.controlPoints[i + 1].x.underlying - bezier.controlPoints[i].x.underlying
                let dy = bezier.controlPoints[i + 1].y.underlying - bezier.controlPoints[i].y.underlying
                derivPoints.append(Point(x: X(dx), y: Y(dy)))
            }

            var points = derivPoints
            while points.count > 1 {
                var next: [Point<2>] = []
                next.reserveCapacity(points.dropLast().count)
                for i in points.indices.dropLast() {
                    let p = points[i].lerp(to: points[i + 1], t: t)
                    next.append(p)
                }
                points = next
            }

            guard let p = points.first else { return nil }
            return Vector(
                dx: Linear<Scalar, Space>.Dx(n * p.x.underlying),
                dy: Linear<Scalar, Space>.Dy(n * p.y.underlying)
            )
        }
    }

    extension Geometry.Bezier {

        @inlinable
        public init<U, E: Swift::Error>(
            _ other: borrowing Geometry<U, Space>.Bezier,
            _ transform: (U) throws(E) -> Scalar
        ) throws(E) {
            var result: [Geometry.Point<2>] = []
            result.reserveCapacity(other.controlPoints.count)
            for point in other.controlPoints {
                result.append(try Geometry.Point<2>(point, transform))
            }
            self.init(controlPoints: result)
        }

        @inlinable
        public func map<Result, E: Swift::Error>(
            _ transform: (Scalar) throws(E) -> Result
        ) throws(E) -> Geometry<Result, Space>.Bezier {
            var result: [Geometry<Result, Space>.Point<2>] = []
            result.reserveCapacity(controlPoints.count)
            for point in controlPoints {
                result.append(try point.map(transform))
            }
            return Geometry<Result, Space>.Bezier(controlPoints: result)
        }
    }

    extension Geometry.Bezier where Scalar: Swift::Numeric {

        @inlinable
        public func transformed<Target>(
            by map: Matrix::Matrix<2, 3, Scalar>,
            to space: Target.Type
        ) -> Geometry<Scalar, Target>.Bezier {
            Geometry<Scalar, Target>.Bezier(
                controlPoints: controlPoints.map { $0.transformed(by: map, to: space) }
            )
        }

        @inlinable
        public func transformed(by map: Matrix::Matrix<2, 3, Scalar>) -> Self {
            transformed(by: map, to: Space.self)
        }
    }

    extension Geometry.Bezier where Scalar: BinaryFloatingPoint {

        /// Appends the vertices strictly inside the curve that make it straight to within `tolerance`.
        @inlinable
        static func flatten(
            _ points: [(x: Scalar, y: Scalar)],
            tolerance: Scalar,
            depth: Int,
            into result: inout [(x: Scalar, y: Scalar, smooth: Bool)]
        ) {
            guard depth > 0, let first = points.first, let last = points.last else { return }
            let chord = (x: last.x - first.x, y: last.y - first.y)
            let squared = chord.x * chord.x + chord.y * chord.y
            var flat = true
            for point in points.dropFirst().dropLast() {
                let offset = (x: point.x - first.x, y: point.y - first.y)
                var along: Scalar = 0
                if squared > 0 {
                    along = min(max((offset.x * chord.x + offset.y * chord.y) / squared, 0), 1)
                }
                let away = (x: offset.x - along * chord.x, y: offset.y - along * chord.y)
                if (away.x * away.x + away.y * away.y).squareRoot() > tolerance { flat = false }
            }
            if flat { return }
            let halves = split(points)
            flatten(halves.left, tolerance: tolerance, depth: depth - 1, into: &result)
            if let middle = halves.left.last { result.append((middle.x, middle.y, true)) }
            flatten(halves.right, tolerance: tolerance, depth: depth - 1, into: &result)
        }

        /// The two halves of a curve cut at its middle parameter, by de Casteljau's construction.
        @inlinable
        static func split(
            _ points: [(x: Scalar, y: Scalar)]
        ) -> (left: [(x: Scalar, y: Scalar)], right: [(x: Scalar, y: Scalar)]) {
            var work = points
            var left: [(x: Scalar, y: Scalar)] = []
            var right: [(x: Scalar, y: Scalar)] = []
            var remaining = work.count
            while remaining > 0 {
                left.append(work[0])
                right.append(work[remaining - 1])
                remaining -= 1
                var index = 0
                while index < remaining {
                    work[index] = (
                        work[index].x / 2 + work[index + 1].x / 2,
                        work[index].y / 2 + work[index + 1].y / 2
                    )
                    index += 1
                }
            }
            right.reverse()
            return (left, right)
        }
    }

#endif
