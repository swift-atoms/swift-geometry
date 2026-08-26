public import Affine_Geometry
import Affine
public import Dimension
public import Linear
import Real

extension Geometry {

    public struct Ellipse {

        public var center: Point<2>

        public var semiMajor: Length

        public var semiMinor: Length

        public var rotation: Radian<Scalar>

        @inlinable
        public init(
            center: consuming Point<2>,
            semiMajor: consuming Length,
            semiMinor: consuming Length,
            rotation: consuming Radian<Scalar>
        ) {
            self.center = center
            self.semiMajor = semiMajor
            self.semiMinor = semiMinor
            self.rotation = rotation
        }
    }
}

extension Geometry.Ellipse: Sendable where Scalar: Sendable {}
extension Geometry.Ellipse: Equatable where Scalar: Equatable {}
extension Geometry.Ellipse: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Ellipse: Codable where Scalar: Codable {}
#endif

extension Geometry.Ellipse where Scalar: AdditiveArithmetic {

    @inlinable
    public init(
        semiMajor: Geometry.Length,
        semiMinor: Geometry.Length
    ) {
        self.init(center: .zero, semiMajor: semiMajor, semiMinor: semiMinor, rotation: .zero)
    }

    @inlinable
    public init(
        center: Geometry.Point<2>,
        semiMajor: Geometry.Length,
        semiMinor: Geometry.Length
    ) {
        self.init(
            center: center,
            semiMajor: semiMajor,
            semiMinor: semiMinor,
            rotation: Radian(_unchecked: Scalar.zero)
        )
    }
}

extension Geometry.Ellipse where Scalar: FloatingPoint {

    @inlinable
    public static func circle(center: Geometry.Point<2>, radius: Geometry.Radius) -> Self {
        Self(center: center, semiMajor: radius, semiMinor: radius, rotation: Radian(_unchecked: 0))
    }
}

extension Geometry.Ellipse where Scalar: FloatingPoint {

    @inlinable
    public var majorAxis: Geometry.Length {
        semiMajor * 2
    }

    @inlinable
    public var minorAxis: Geometry.Length {
        semiMinor * 2
    }

    @inlinable
    public var eccentricity: Scale<1, Scalar> {

        let aSq = semiMajor * semiMajor
        let bSq = semiMinor * semiMinor

        return sqrt((aSq - bSq) / aSq)
    }

    @inlinable
    public var focalDistance: Geometry.Distance {

        let aSq = semiMajor * semiMajor
        let bSq = semiMinor * semiMinor
        return sqrt(aSq - bSq)
    }
}

extension Geometry.Ellipse where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public var foci: (f1: Geometry.Point<2>, f2: Geometry.Point<2>) {
        let c: Scalar = focalDistance.underlying
        let cosVal: Scalar = rotation.cos.value
        let sinVal: Scalar = rotation.sin.value

        let dx: Scalar = c * cosVal
        let dy: Scalar = c * sinVal

        return (
            Geometry.Point(
                x: center.x - Geometry.Width(dx),
                y: center.y - Geometry.Height(dy)
            ),
            Geometry.Point(
                x: center.x + Geometry.Width(dx),
                y: center.y + Geometry.Height(dy)
            )
        )
    }
}

extension Geometry.Ellipse where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public var area: Geometry.Area { Geometry.area(of: self) }
}

extension Geometry.Ellipse where Scalar: FloatingPoint {

    @inlinable
    public var perimeter: Geometry.Perimeter {
        let a: Scalar = semiMajor.underlying
        let b: Scalar = semiMinor.underlying
        let diff: Scalar = a - b
        let sum: Scalar = a + b
        let h: Scalar = (diff * diff) / (sum * sum)
        let sqrtTerm: Scalar = (4 - 3 * h).squareRoot()
        let hTerm: Scalar = 3 * h / (10 + sqrtTerm)
        let factor: Scalar = 1 + hTerm
        let perimeter: Scalar = Scalar.pi * sum * factor
        return Geometry.Length(perimeter)
    }

    @inlinable
    public var isCircle: Bool {
        semiMajor == semiMinor
    }
}

extension Geometry.Ellipse where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public func point(at t: Radian<Scalar>) -> Geometry.Point<2> {
        Geometry.point(of: self, at: t)
    }

    @inlinable
    public func tangent(at t: Radian<Scalar>) -> Geometry.Vector<2> {
        let cosT: Scalar = t.cos.value
        let sinT: Scalar = t.sin.value
        let a: Scalar = semiMajor.underlying
        let b: Scalar = semiMinor.underlying

        let dx: Scalar = -a * sinT
        let dy: Scalar = b * cosT

        let cosR: Scalar = rotation.cos.value
        let sinR: Scalar = rotation.sin.value

        return Geometry.Vector(
            dx: Linear<Scalar, Space>.Dx(dx * cosR - dy * sinR),
            dy: Linear<Scalar, Space>.Dy(dx * sinR + dy * cosR)
        )
    }
}

extension Geometry.Ellipse where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public func contains(_ point: Geometry.Point<2>) -> Bool {
        Geometry.contains(self, point: point)
    }
}

extension Geometry.Ellipse where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public var boundingBox: Geometry.Rectangle {

        let aSq = semiMajor * semiMajor
        let bSq = semiMinor * semiMinor

        let cosSq = rotation.cos * rotation.cos
        let sinSq = rotation.sin * rotation.sin

        let halfWidth: Geometry.Length = sqrt(aSq * cosSq + bSq * sinSq)
        let halfHeight: Geometry.Length = sqrt(aSq * sinSq + bSq * cosSq)

        return Geometry.Rectangle(
            llx: center.x - halfWidth,
            lly: center.y - halfHeight,
            urx: center.x + halfWidth,
            ury: center.y + halfHeight
        )
    }
}

extension Geometry.Ellipse where Scalar: FloatingPoint {

    @inlinable
    public init(_ circle: Geometry.Circle) {
        self.init(
            center: circle.center,
            semiMajor: circle.radius,
            semiMinor: circle.radius,
            rotation: .zero
        )
    }
}

extension Geometry.Ellipse where Scalar: FloatingPoint {

    @inlinable
    public func translated(by vector: Geometry.Vector<2>) -> Self {
        Self(
            center: center + vector,
            semiMajor: semiMajor,
            semiMinor: semiMinor,
            rotation: rotation
        )
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>) -> Self {
        Self(
            center: center,
            semiMajor: semiMajor * factor,
            semiMinor: semiMinor * factor,
            rotation: rotation
        )
    }

    @inlinable
    public func rotated(by angle: Radian<Scalar>) -> Self {
        Self(
            center: center,
            semiMajor: semiMajor,
            semiMinor: semiMinor,
            rotation: rotation + angle
        )
    }
}

extension Geometry where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public static func area(of ellipse: Ellipse) -> Area {
        Scale<1, Scalar>.pi * ellipse.semiMajor * ellipse.semiMinor
    }
}

extension Geometry where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public static func contains(_ ellipse: Ellipse, point: Point<2>) -> Bool {

        let dx: Scalar = point.x.underlying - ellipse.center.x.underlying
        let dy: Scalar = point.y.underlying - ellipse.center.y.underlying

        let cosR: Scalar = ellipse.rotation.cos.value
        let sinR: Scalar = ellipse.rotation.sin.value
        let localX: Scalar = dx * cosR + dy * sinR
        let localY: Scalar = -dx * sinR + dy * cosR

        let a: Scalar = ellipse.semiMajor.underlying
        let b: Scalar = ellipse.semiMinor.underlying
        let aSq: Scalar = a * a
        let bSq: Scalar = b * b
        let one: Scalar = 1
        return (localX * localX) / aSq + (localY * localY) / bSq <= one
    }

    @inlinable
    public static func point(of ellipse: Ellipse, at t: Radian<Scalar>) -> Point<2> {
        let cosT: Scalar = t.cos.value
        let sinT: Scalar = t.sin.value
        let a: Scalar = ellipse.semiMajor.underlying
        let b: Scalar = ellipse.semiMinor.underlying

        let x: Scalar = a * cosT
        let y: Scalar = b * sinT

        let cosR: Scalar = ellipse.rotation.cos.value
        let sinR: Scalar = ellipse.rotation.sin.value

        let cx: Scalar = ellipse.center.x.underlying
        let cy: Scalar = ellipse.center.y.underlying

        return Point(
            x: Affine.Continuous<Scalar, Space>.X(cx + x * cosR - y * sinR),
            y: Affine.Continuous<Scalar, Space>.Y(cy + x * sinR + y * cosR)
        )
    }
}

extension Geometry.Ellipse {

    @inlinable
    public init<U, E: Swift.Error>(
        _ other: borrowing Geometry<U, Space>.Ellipse,
        _ transform: (U) throws(E) -> Scalar
    ) throws(E) {
        self.init(
            center: try Affine.Continuous<Scalar, Space>.Point<2>(other.center, transform),
            semiMajor: try other.semiMajor.map(transform),
            semiMinor: try other.semiMinor.map(transform),
            rotation: Radian(_unchecked: try transform(other.rotation.underlying))
        )
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Ellipse {
        .init(
            center: try center.map(transform),
            semiMajor: try semiMajor.map(transform),
            semiMinor: try semiMinor.map(transform),
            rotation: Radian(_unchecked: try transform(rotation.underlying))
        )
    }
}

extension Geometry.Ellipse {

    public struct Arc {

        public var center: Geometry.Point<2>

        public var semiMajor: Geometry.Length

        public var semiMinor: Geometry.Length

        public var rotation: Radian<Scalar>

        public var startAngle: Radian<Scalar>

        public var endAngle: Radian<Scalar>

        @inlinable
        public init(
            center: consuming Geometry.Point<2>,
            semiMajor: consuming Geometry.Length,
            semiMinor: consuming Geometry.Length,
            rotation: consuming Radian<Scalar>,
            startAngle: consuming Radian<Scalar>,
            endAngle: consuming Radian<Scalar>
        ) {
            self.center = center
            self.semiMajor = semiMajor
            self.semiMinor = semiMinor
            self.rotation = rotation
            self.startAngle = startAngle
            self.endAngle = endAngle
        }
    }
}

extension Geometry.Ellipse.Arc: Sendable where Scalar: Sendable {}
extension Geometry.Ellipse.Arc: Equatable where Scalar: Equatable {}
extension Geometry.Ellipse.Arc: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Ellipse.Arc: Codable where Scalar: Codable {}
#endif

extension Geometry.Ellipse.Arc where Scalar: AdditiveArithmetic & Comparable {

    @inlinable
    public var sweep: Radian<Scalar> {
        endAngle - startAngle
    }

    @inlinable
    public var isCounterClockwise: Bool {
        sweep > .zero
    }
}

extension Geometry.Ellipse.Arc where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public var isFullEllipse: Bool {
        abs(sweep) >= Radian.pi.two
    }
}

extension Geometry.Ellipse.Arc where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public var startPoint: Geometry.Point<2> {
        point(at: Scale(0))
    }

    @inlinable
    public var endPoint: Geometry.Point<2> {
        point(at: Scale(1))
    }

    @inlinable
    public var midPoint: Geometry.Point<2> {
        point(at: Scale(0.5))
    }
}

extension Geometry.Ellipse.Arc where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public func point(at t: Scale<1, Scalar>) -> Geometry.Point<2> {
        let angle = startAngle + t * sweep
        return pointAtAngle(angle)
    }

    @inlinable
    package func pointAtAngle(_ angle: Radian<Scalar>) -> Geometry.Point<2> {
        let cosT = angle.cos
        let sinT = angle.sin

        let a = semiMajor.underlying
        let b = semiMinor.underlying
        let x = a * cosT.value
        let y = b * sinT.value

        let cosR = rotation.cos
        let sinR = rotation.sin

        return Geometry.Point(
            x: center.x + Geometry.Width(x * cosR.value - y * sinR.value),
            y: center.y + Geometry.Height(x * sinR.value + y * cosR.value)
        )
    }

    @inlinable
    public func tangent(at t: Scale<1, Scalar>) -> Geometry.Vector<2> {
        let angle = startAngle + t * sweep
        let cosT = angle.cos
        let sinT = angle.sin

        let a = semiMajor.underlying
        let b = semiMinor.underlying
        let dx = -a * sinT.value
        let dy = b * cosT.value

        let cosR = rotation.cos
        let sinR = rotation.sin

        let sign: Scalar = sweep.underlying >= 0 ? 1 : -1

        return Geometry.Vector(
            dx: Geometry.Dx(sign * (dx * cosR.value - dy * sinR.value)),
            dy: Geometry.Dy(sign * (dx * sinR.value + dy * cosR.value))
        )
    }
}

extension Geometry.Ellipse.Arc where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public func length(segments: Int = 100) -> Geometry.ArcLength {
        guard segments > 0 else { return .zero }

        var total: Geometry.ArcLength = .zero
        var prev = startPoint

        (1...segments).forEach { i in
            let t = Scale<1, Scalar>(Scalar(i) / Scalar(segments))
            let current = point(at: t)
            total += prev.distance(to: current)
            prev = current
        }

        return total
    }
}

extension Geometry.Ellipse.Arc where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public var boundingBox: Geometry.Rectangle {

        if isFullEllipse {
            return Geometry.Ellipse(
                center: center,
                semiMajor: semiMajor,
                semiMinor: semiMinor,
                rotation: rotation
            ).boundingBox
        }

        let p0 = startPoint
        let p1 = endPoint

        var minX = min(p0.x.underlying, p1.x.underlying)
        var maxX = max(p0.x.underlying, p1.x.underlying)
        var minY = min(p0.y.underlying, p1.y.underlying)
        var maxY = max(p0.y.underlying, p1.y.underlying)

        let a = semiMajor.underlying
        let b = semiMinor.underlying
        let phi = rotation.underlying

        let tanPhi = Scalar._tan(phi)
        let xExtremaAngle = Scalar._atan2(-b * tanPhi, a)

        let yExtremaAngle = Scalar._atan2(b, a * tanPhi)

        for baseAngle in [xExtremaAngle, xExtremaAngle + .pi, yExtremaAngle, yExtremaAngle + .pi] {
            if containsAngle(Radian(_unchecked: baseAngle)) {
                let pt = pointAtAngle(Radian(_unchecked: baseAngle))
                minX = min(minX, pt.x.underlying)
                maxX = max(maxX, pt.x.underlying)
                minY = min(minY, pt.y.underlying)
                maxY = max(maxY, pt.y.underlying)
            }
        }

        return Geometry.Rectangle(
            llx: Geometry.X(minX),
            lly: Geometry.Y(minY),
            urx: Geometry.X(maxX),
            ury: Geometry.Y(maxY)
        )
    }

    @inlinable
    package func containsAngle(_ angle: Radian<Scalar>) -> Bool {
        let a = angle.underlying
        let s = startAngle.underlying
        let e = endAngle.underlying
        let sweepVal = sweep.underlying

        let twoPi = Scalar.pi * 2
        let normA = a - (a / twoPi).rounded(.down) * twoPi
        let normS = s - (s / twoPi).rounded(.down) * twoPi
        let normE = e - (e / twoPi).rounded(.down) * twoPi

        guard sweepVal >= 0 else {
            guard normS >= normE else { return normA <= normS || normA >= normE }
            return normA <= normS && normA >= normE
        }
        guard normS <= normE else { return normA >= normS || normA <= normE }
        return normA >= normS && normA <= normE
    }
}

extension Geometry.Ellipse.Arc where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public func contains(_ point: Geometry.Point<2>) -> Bool {

        let dx = point.x.underlying - center.x.underlying
        let dy = point.y.underlying - center.y.underlying

        let cosR = rotation.cos.value
        let sinR = rotation.sin.value
        let localX = dx * cosR + dy * sinR
        let localY = -dx * sinR + dy * cosR

        let a = semiMajor.underlying
        let b = semiMinor.underlying
        let aSq: Scalar = a * a
        let bSq: Scalar = b * b
        let xTerm: Scalar = (localX * localX) / aSq
        let yTerm: Scalar = (localY * localY) / bSq
        let ellipseVal: Scalar = xTerm + yTerm

        let tolerance: Scalar = Scalar.ulpOfOne * 1000
        guard abs(ellipseVal - 1) < tolerance else { return false }

        let pointAngle = Radian(_unchecked: Scalar._atan2(localY / b, localX / a))
        return containsAngle(pointAngle)
    }
}

extension Geometry.Ellipse.Arc where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public init(
        from start: Geometry.Point<2>,
        to end: Geometry.Point<2>,
        rx: Geometry.Length,
        ry: Geometry.Length,
        xAxisRotation: Radian<Scalar>,
        largeArcFlag: Bool,
        sweepFlag: Bool
    ) {

        let x1 = start.x.underlying
        let y1 = start.y.underlying
        let x2 = end.x.underlying
        let y2 = end.y.underlying

        if x1 == x2 && y1 == y2 {

            self.init(
                center: start,
                semiMajor: rx,
                semiMinor: ry,
                rotation: xAxisRotation,
                startAngle: .zero,
                endAngle: .zero
            )
            return
        }

        var rxVal = abs(rx.underlying)
        var ryVal = abs(ry.underlying)

        if rxVal == 0 || ryVal == 0 {

            let midX = (x1 + x2) / 2
            let midY = (y1 + y2) / 2
            self.init(
                center: Geometry.Point(x: Geometry.X(midX), y: Geometry.Y(midY)),
                semiMajor: Geometry.Length(rxVal),
                semiMinor: Geometry.Length(ryVal),
                rotation: xAxisRotation,
                startAngle: .zero,
                endAngle: .zero
            )
            return
        }

        let phi = xAxisRotation.underlying
        let cosPhi = Scalar._cos(phi)
        let sinPhi = Scalar._sin(phi)

        let dx = (x1 - x2) / 2
        let dy = (y1 - y2) / 2
        let x1Prime = cosPhi * dx + sinPhi * dy
        let y1Prime = -sinPhi * dx + cosPhi * dy

        let rxSqInit: Scalar = rxVal * rxVal
        let rySqInit: Scalar = ryVal * ryVal
        let lambdaX: Scalar = (x1Prime * x1Prime) / rxSqInit
        let lambdaY: Scalar = (y1Prime * y1Prime) / rySqInit
        let lambda: Scalar = lambdaX + lambdaY
        if lambda > 1 {
            let sqrtLambda = Scalar._sqrt(lambda)
            rxVal *= sqrtLambda
            ryVal *= sqrtLambda
        }

        let rxSq: Scalar = rxVal * rxVal
        let rySq: Scalar = ryVal * ryVal
        let x1PrimeSq: Scalar = x1Prime * x1Prime
        let y1PrimeSq: Scalar = y1Prime * y1Prime

        let sqNumerator: Scalar = rxSq * rySq - rxSq * y1PrimeSq - rySq * x1PrimeSq
        let sqDenominator: Scalar = rxSq * y1PrimeSq + rySq * x1PrimeSq
        var sq: Scalar = sqNumerator / sqDenominator
        sq = max(0, sq)
        var sqrtVal: Scalar = Scalar._sqrt(sq)

        if largeArcFlag == sweepFlag {
            sqrtVal = -sqrtVal
        }

        let cxPrime: Scalar = sqrtVal * rxVal * y1Prime / ryVal
        let cyPrime: Scalar = sqrtVal * ryVal * x1Prime / rxVal * (-1)

        let midX = (x1 + x2) / 2
        let midY = (y1 + y2) / 2
        let cx = cosPhi * cxPrime - sinPhi * cyPrime + midX
        let cy = sinPhi * cxPrime + cosPhi * cyPrime + midY

        let ux: Scalar = 1
        let uy: Scalar = 0
        let vx = (x1Prime - cxPrime) / rxVal
        let vy = (y1Prime - cyPrime) / ryVal

        let startAngleVal = Self.angleBetween(ux: ux, uy: uy, vx: vx, vy: vy)

        let wx = (-x1Prime - cxPrime) / rxVal
        let wy = (-y1Prime - cyPrime) / ryVal

        var dTheta = Self.angleBetween(ux: vx, uy: vy, vx: wx, vy: wy)

        if !sweepFlag && dTheta > 0 {
            dTheta -= Scalar.pi * 2
        } else if sweepFlag && dTheta < 0 {
            dTheta += Scalar.pi * 2
        }

        let endAngleVal: Scalar = startAngleVal + dTheta
        self.init(
            center: Geometry.Point(x: Geometry.X(cx), y: Geometry.Y(cy)),
            semiMajor: Geometry.Length(rxVal),
            semiMinor: Geometry.Length(ryVal),
            rotation: xAxisRotation,
            startAngle: Radian(_unchecked: startAngleVal),
            endAngle: Radian(_unchecked: endAngleVal)
        )
    }

    @inlinable
    package static func angleBetween(ux: Scalar, uy: Scalar, vx: Scalar, vy: Scalar) -> Scalar {
        let dot = ux * vx + uy * vy
        let lenU = Scalar._sqrt(ux * ux + uy * uy)
        let lenV = Scalar._sqrt(vx * vx + vy * vy)
        var cosAngle = dot / (lenU * lenV)

        cosAngle = max(-1, min(1, cosAngle))
        let angle = Scalar._acos(cosAngle)

        let cross = ux * vy - uy * vx
        return cross >= 0 ? angle : -angle
    }
}

extension Array {

    @inlinable
    public init<Scalar: BinaryFloatingPoint & Numeric.Transcendental, Space>(
        ellipticalArc arc: Geometry<Scalar, Space>.Ellipse.Arc
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

            let bezier = Self.ellipticalArcSegmentToBezier(
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
    package static func ellipticalArcSegmentToBezier<
        Scalar: BinaryFloatingPoint & Numeric.Transcendental,
        Space
    >(
        arc: Geometry<Scalar, Space>.Ellipse.Arc,
        from startAngle: Radian<Scalar>,
        to endAngle: Radian<Scalar>
    ) -> Geometry<Scalar, Space>.Bezier where Element == Geometry<Scalar, Space>.Bezier {
        let sweepRaw = (endAngle - startAngle).underlying
        let halfSweepRaw = sweepRaw / 2

        let k = Scalar(4.0 / 3.0) * Scalar._tan(halfSweepRaw / 2)

        let cx = arc.center.x.underlying
        let cy = arc.center.y.underlying
        let a = arc.semiMajor.underlying
        let b = arc.semiMinor.underlying
        let phi = arc.rotation.underlying
        let cosPhi = Scalar._cos(phi)
        let sinPhi = Scalar._sin(phi)

        let cosStart = Scalar._cos(startAngle.underlying)
        let sinStart = Scalar._sin(startAngle.underlying)
        let cosEnd = Scalar._cos(endAngle.underlying)
        let sinEnd = Scalar._sin(endAngle.underlying)

        let ux0 = a * cosStart
        let uy0 = b * sinStart
        let p0x = cx + ux0 * cosPhi - uy0 * sinPhi
        let p0y = cy + ux0 * sinPhi + uy0 * cosPhi

        let ux3 = a * cosEnd
        let uy3 = b * sinEnd
        let p3x = cx + ux3 * cosPhi - uy3 * sinPhi
        let p3y = cy + ux3 * sinPhi + uy3 * cosPhi

        let t0x = -a * sinStart
        let t0y = b * cosStart
        let t1x = -a * sinEnd
        let t1y = b * cosEnd

        let rt0x = t0x * cosPhi - t0y * sinPhi
        let rt0y = t0x * sinPhi + t0y * cosPhi
        let rt1x = t1x * cosPhi - t1y * sinPhi
        let rt1y = t1x * sinPhi + t1y * cosPhi

        let p1x = p0x + k * rt0x
        let p1y = p0y + k * rt0y
        let p2x = p3x - k * rt1x
        let p2y = p3y - k * rt1y

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

extension Geometry.Ellipse.Arc where Scalar: FloatingPoint {

    @inlinable
    public func translated(by vector: Geometry.Vector<2>) -> Self {
        Self(
            center: center + vector,
            semiMajor: semiMajor,
            semiMinor: semiMinor,
            rotation: rotation,
            startAngle: startAngle,
            endAngle: endAngle
        )
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>) -> Self {
        Self(
            center: center,
            semiMajor: semiMajor * factor,
            semiMinor: semiMinor * factor,
            rotation: rotation,
            startAngle: startAngle,
            endAngle: endAngle
        )
    }

    @inlinable
    public var reversed: Self {
        Self(
            center: center,
            semiMajor: semiMajor,
            semiMinor: semiMinor,
            rotation: rotation,
            startAngle: endAngle,
            endAngle: startAngle
        )
    }
}

extension Geometry.Ellipse.Arc {

    @inlinable
    public init<U, E: Swift.Error>(
        _ other: borrowing Geometry<U, Space>.Ellipse.Arc,
        _ transform: (U) throws(E) -> Scalar
    ) throws(E) {
        self.init(
            center: try Affine.Continuous<Scalar, Space>.Point<2>(other.center, transform),
            semiMajor: try other.semiMajor.map(transform),
            semiMinor: try other.semiMinor.map(transform),
            rotation: Radian(_unchecked: try transform(other.rotation.underlying)),
            startAngle: Radian(_unchecked: try transform(other.startAngle.underlying)),
            endAngle: Radian(_unchecked: try transform(other.endAngle.underlying))
        )
    }

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Ellipse.Arc {
        .init(
            center: try center.map(transform),
            semiMajor: try semiMajor.map(transform),
            semiMinor: try semiMinor.map(transform),
            rotation: Radian(_unchecked: try transform(rotation.underlying)),
            startAngle: Radian(_unchecked: try transform(startAngle.underlying)),
            endAngle: Radian(_unchecked: try transform(endAngle.underlying))
        )
    }
}
