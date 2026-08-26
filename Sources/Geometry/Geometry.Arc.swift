public import Affine_Geometry
import Affine
public import Dimension
public import Linear
import Real

extension Geometry {

    public struct Arc {

        public var center: Point<2>

        public var radius: Radius

        public var startAngle: Radian<Scalar>

        public var endAngle: Radian<Scalar>

        @inlinable
        public init(
            center: consuming Point<2>,
            radius: consuming Radius,
            startAngle: consuming Radian<Scalar>,
            endAngle: consuming Radian<Scalar>
        ) {
            self.center = center
            self.radius = radius
            self.startAngle = startAngle
            self.endAngle = endAngle
        }
    }
}

extension Geometry.Arc: Sendable where Scalar: Sendable {}
extension Geometry.Arc: Equatable where Scalar: Equatable {}
extension Geometry.Arc: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Arc: Codable where Scalar: Codable {}
#endif

extension Geometry.Arc where Scalar: BinaryFloatingPoint {

    @inlinable
    public static func semicircle(
        center: Geometry.Point<2>,
        radius: Geometry.Radius,
        startAngle: Radian<Scalar> = .zero
    ) -> Self {
        Self(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: startAngle + .pi
        )
    }
}

extension Geometry.Arc where Scalar: BinaryFloatingPoint {

    @inlinable
    public static func fullCircle(center: Geometry.Point<2>, radius: Geometry.Radius) -> Self {
        Self(
            center: center,
            radius: radius,
            startAngle: .zero,
            endAngle: .pi.two
        )
    }

    @inlinable
    public static func quarterCircle(
        center: Geometry.Point<2>,
        radius: Geometry.Radius,
        startAngle: Radian<Scalar> = .zero
    ) -> Self {
        Self(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: startAngle + .pi.half
        )
    }
}

extension Geometry.Arc where Scalar: AdditiveArithmetic & Comparable {

    @inlinable
    public var sweep: Radian<Scalar> {
        endAngle - startAngle
    }

    @inlinable
    public var isCounterClockwise: Bool {
        sweep > .zero
    }
}

extension Geometry.Arc where Scalar: BinaryFloatingPoint {

    @inlinable
    public var isFullCircle: Bool {
        abs(sweep) >= Radian.pi.two
    }
}

extension Geometry.Arc where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public var startPoint: Geometry.Point<2> {

        Geometry.Point(
            x: center.x + radius * startAngle.cos,
            y: center.y + radius * startAngle.sin
        )
    }

    @inlinable
    public var endPoint: Geometry.Point<2> {
        Geometry.Point(
            x: center.x + radius * endAngle.cos,
            y: center.y + radius * endAngle.sin
        )
    }

    @inlinable
    public var midPoint: Geometry.Point<2> {
        let midAngle = (startAngle + endAngle) / 2
        return Geometry.Point(
            x: center.x + radius * midAngle.cos,
            y: center.y + radius * midAngle.sin
        )
    }
}

extension Geometry.Arc where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public func point(at t: Scale<1, Scalar>) -> Geometry.Point<2> {
        let angle = startAngle + t * sweep
        return Geometry.Point(
            x: center.x + radius * angle.cos,
            y: center.y + radius * angle.sin
        )
    }

    @inlinable
    public func tangent(at t: Scale<1, Scalar>) -> Geometry.Vector<2> {
        let angle = startAngle + t * sweep

        let sign: Scalar = sweep.underlying >= 0 ? 1 : -1
        return Geometry.Vector(
            dx: Linear<Scalar, Space>.Dx(-sign * angle.sin.value),
            dy: Linear<Scalar, Space>.Dy(sign * angle.cos.value)
        )
    }
}

extension Geometry.Arc where Scalar: BinaryFloatingPoint {

    @inlinable
    public var length: Geometry.ArcLength {

        radius * Scale(abs(sweep.underlying))
    }
}

extension Geometry.Arc where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public var boundingBox: Geometry.Rectangle { Geometry.boundingBox(of: self) }
}

extension Geometry where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public static func boundingBox(of arc: Arc) -> Rectangle {
        let cx = arc.center.x.underlying
        let cy = arc.center.y.underlying
        let r = arc.radius.underlying

        if arc.isFullCircle {
            return Rectangle(
                llx: X(cx - r),
                lly: Y(cy - r),
                urx: X(cx + r),
                ury: Y(cy + r)
            )
        }

        var minX = min(arc.startPoint.x.underlying, arc.endPoint.x.underlying)
        var maxX = max(arc.startPoint.x.underlying, arc.endPoint.x.underlying)
        var minY = min(arc.startPoint.y.underlying, arc.endPoint.y.underlying)
        var maxY = max(arc.startPoint.y.underlying, arc.endPoint.y.underlying)

        let start = arc.startAngle.normalized
        let end = arc.endAngle.normalized
        let sweep = arc.sweep.underlying

        func containsAngle(_ angle: Radian<Scalar>) -> Bool {
            let a = angle.underlying
            let s = start.underlying
            let e = end.underlying
            guard sweep >= 0 else {
                guard s >= e else { return a <= s || a >= e }
                return a <= s && a >= e
            }
            guard s <= e else { return a >= s || a <= e }
            return a >= s && a <= e
        }

        if containsAngle(Radian<Scalar>.zero) {
            maxX = max(maxX, cx + r)
        }

        if containsAngle(Radian<Scalar>.pi.half) {
            maxY = max(maxY, cy + r)
        }

        if containsAngle(Radian(_unchecked: Scalar.pi)) {
            minX = min(minX, cx - r)
        }

        if containsAngle(Radian(_unchecked: Scalar.pi * 1.5)) {
            minY = min(minY, cy - r)
        }

        return Rectangle(
            llx: X(minX),
            lly: Y(minY),
            urx: X(maxX),
            ury: Y(maxY)
        )
    }
}

extension Geometry.Arc where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public func contains(_ point: Geometry.Point<2>) -> Bool {

        let dist = center.distance(to: point)
        guard abs(dist.underlying - radius.underlying) < Scalar.ulpOfOne * 100 else { return false }

        let dx = point.x - center.x
        let dy = point.y - center.y
        let pointAngle: Radian<Scalar> = Radian.atan2(y: dy, x: dx)

        return angleIsInArc(pointAngle)
    }

    @inlinable
    package func angleIsInArc(_ angle: Radian<Scalar>) -> Bool {
        let normAngle = angle.normalized
        let normStart = startAngle.normalized
        let normEnd = endAngle.normalized

        guard sweep.underlying >= 0 else {
            guard normStart >= normEnd else {
                return normAngle <= normStart || normAngle >= normEnd
            }
            return normAngle <= normStart && normAngle >= normEnd
        }
        guard normStart <= normEnd else {
            return normAngle >= normStart || normAngle <= normEnd
        }
        return normAngle >= normStart && normAngle <= normEnd
    }
}

extension Array {

    @inlinable
    public init<Scalar: BinaryFloatingPoint & Numeric.Transcendental, Space>(
        arc: Geometry<Scalar, Space>.Arc
    ) where Element == Geometry<Scalar, Space>.Bezier {
        let sweepRaw = arc.sweep.underlying
        guard abs(sweepRaw) > 0 else {
            self = []
            return
        }

        let maxAngle = Scalar.pi / 2

        let segmentCount = Int((abs(sweepRaw) / maxAngle).rounded(.up))
        let segmentAngle = sweepRaw / Scalar(segmentCount)

        var beziers: [Geometry<Scalar, Space>.Bezier] = []
        beziers.reserveCapacity(segmentCount)

        var currentAngle = arc.startAngle

        for _ in 0..<segmentCount {
            let nextAngle: Radian<Scalar> = currentAngle + Radian(_unchecked: segmentAngle)

            let bezier = Self.arcSegmentToBezier(
                arc: arc,
                from: currentAngle,
                to: nextAngle
            )
            beziers.append(bezier)

            currentAngle = nextAngle
        }

        self = beziers
    }

    @inlinable
    package static func arcSegmentToBezier<
        Scalar: BinaryFloatingPoint & Numeric.Transcendental,
        Space
    >(
        arc: Geometry<Scalar, Space>.Arc,
        from startAngle: Radian<Scalar>,
        to endAngle: Radian<Scalar>
    ) -> Geometry<Scalar, Space>.Bezier where Element == Geometry<Scalar, Space>.Bezier {
        let sweepRaw = (endAngle - startAngle).underlying
        let halfSweepRaw = sweepRaw / 2

        let halfAngle = Radian<Scalar>(_unchecked: halfSweepRaw / 2)
        let k = Scalar(4.0 / 3.0) * halfAngle.tan.value

        let cx = arc.center.x.underlying
        let cy = arc.center.y.underlying
        let r = arc.radius.underlying

        let cosStart = startAngle.cos.value
        let sinStart = startAngle.sin.value
        let cosEnd = endAngle.cos.value
        let sinEnd = endAngle.sin.value

        let p0x = cx + r * cosStart
        let p0y = cy + r * sinStart
        let p3x = cx + r * cosEnd
        let p3y = cy + r * sinEnd

        let t0x = -sinStart
        let t0y = cosStart
        let t1x = -sinEnd
        let t1y = cosEnd

        let p1x = p0x + k * r * t0x
        let p1y = p0y + k * r * t0y
        let p2x = p3x - k * r * t1x
        let p2y = p3y - k * r * t1y

        let p0 = Geometry<Scalar, Space>.Point(
            x: Geometry<Scalar, Space>.X(p0x),
            y: Geometry<Scalar, Space>.Y(p0y)
        )
        let p1 = Geometry<Scalar, Space>.Point(
            x: Geometry<Scalar, Space>.X(p1x),
            y: Geometry<Scalar, Space>.Y(p1y)
        )
        let p2 = Geometry<Scalar, Space>.Point(
            x: Geometry<Scalar, Space>.X(p2x),
            y: Geometry<Scalar, Space>.Y(p2y)
        )
        let p3 = Geometry<Scalar, Space>.Point(
            x: Geometry<Scalar, Space>.X(p3x),
            y: Geometry<Scalar, Space>.Y(p3y)
        )

        return .cubic(
            from: p0,
            control1: p1,
            control2: p2,
            to: p3
        )
    }
}

extension Geometry.Arc where Scalar: BinaryFloatingPoint {

    @inlinable
    public func translated(by vector: Geometry.Vector<2>) -> Self {
        Self(center: center + vector, radius: radius, startAngle: startAngle, endAngle: endAngle)
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>) -> Self {
        Self(
            center: center,
            radius: radius * factor,
            startAngle: startAngle,
            endAngle: endAngle
        )
    }

    @inlinable
    public var reversed: Self {
        Self(center: center, radius: radius, startAngle: endAngle, endAngle: startAngle)
    }
}

extension Geometry.Arc {

    @inlinable
    public init<U, E: Swift.Error>(
        _ other: borrowing Geometry<U, Space>.Arc,
        _ transform: (U) throws(E) -> Scalar
    ) throws(E) {
        self.init(
            center: try Affine.Continuous<Scalar, Space>.Point<2>(other.center, transform),
            radius: try other.radius.map(transform),
            startAngle: Radian(_unchecked: try transform(other.startAngle.underlying)),
            endAngle: Radian(_unchecked: try transform(other.endAngle.underlying))
        )
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Arc {
        .init(
            center: try center.map(transform),
            radius: try radius.map(transform),
            startAngle: Radian(_unchecked: try transform(startAngle.underlying)),
            endAngle: Radian(_unchecked: try transform(endAngle.underlying))
        )
    }
}
