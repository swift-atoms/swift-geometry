public import Affine_Geometry_Primitives
public import Dimension_Primitives
public import Linear_Primitives

extension Geometry {

    public struct Orthotope<let N: Int> {

        public var center: Point<N>

        public var halfExtents: Size<N>

        @inlinable
        public init(center: consuming Point<N>, halfExtents: consuming Size<N>) {
            self.center = center
            self.halfExtents = halfExtents
        }
    }
}

extension Geometry {

    public typealias Rectangle = Orthotope<2>

    public typealias Cuboid = Orthotope<3>
}

extension Geometry.Orthotope: Sendable where Scalar: Sendable {}
extension Geometry.Orthotope: Equatable where Scalar: Equatable {}
extension Geometry.Orthotope: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Orthotope: Codable where Scalar: Codable {}
#endif

extension Geometry.Orthotope where Scalar: AdditiveArithmetic {

    @inlinable
    public init(halfExtents: Geometry.Size<N>) {
        self.init(center: .zero, halfExtents: halfExtents)
    }
}

extension Geometry.Orthotope where Scalar: ExpressibleByIntegerLiteral & AdditiveArithmetic {

    @inlinable
    public static var unit: Self {
        Self(center: .zero, halfExtents: Geometry.Size(InlineArray(repeating: 1)))
    }
}

extension Geometry.Orthotope where N == 2, Scalar: FloatingPoint {

    @inlinable
    public var llx: Geometry.X {
        get { center.x - halfExtents.width }
        set {
            let oldUrx = center.x + halfExtents.width
            let newWidth: Geometry.Width = Dimension_Primitives.width((oldUrx - newValue) / 2)
            center = Geometry.Point(
                x: newValue + newWidth,
                y: center.y
            )
            halfExtents.width = newWidth
        }
    }

    @inlinable
    public var lly: Geometry.Y {
        get { center.y - halfExtents.height }
        set {
            let oldUry = center.y + halfExtents.height
            let newHeight: Geometry.Height = Dimension_Primitives.height((oldUry - newValue) / 2)
            center = Geometry.Point(
                x: center.x,
                y: newValue + newHeight
            )
            halfExtents.height = newHeight
        }
    }

    @inlinable
    public var urx: Geometry.X {
        get { center.x + halfExtents.width }
        set {
            let oldLlx = center.x - halfExtents.width
            let newWidth: Geometry.Width = Dimension_Primitives.width((newValue - oldLlx) / 2)
            center = Geometry.Point(
                x: oldLlx + newWidth,
                y: center.y
            )
            halfExtents.width = newWidth
        }
    }

    @inlinable
    public var ury: Geometry.Y {
        get { center.y + halfExtents.height }
        set {
            let oldLly = center.y - halfExtents.height
            let newHeight: Geometry.Height = Dimension_Primitives.height((newValue - oldLly) / 2)
            center = Geometry.Point(
                x: center.x,
                y: oldLly + newHeight
            )
            halfExtents.height = newHeight
        }
    }

    @inlinable
    public var width: Geometry.Width {
        get { halfExtents.width * 2 }
        set { halfExtents.width = newValue / 2 }
    }

    @inlinable
    public var height: Geometry.Height {
        get { halfExtents.height * 2 }
        set { halfExtents.height = newValue / 2 }
    }
}

extension Geometry.Orthotope where N == 2, Scalar: FloatingPoint {

    @inlinable
    public init(
        llx: Geometry.X,
        lly: Geometry.Y,
        urx: Geometry.X,
        ury: Geometry.Y
    ) {
        self.init(
            center: Geometry.Point(
                x: llx + (urx - llx) / 2,
                y: lly + (ury - lly) / 2
            ),
            halfExtents: Geometry.Size(
                width: Dimension_Primitives.width((urx - llx) / 2),
                height: Dimension_Primitives.height((ury - lly) / 2)
            )
        )
    }

    @inlinable
    public init(
        x: Geometry.X,
        y: Geometry.Y,
        width: Geometry.Width,
        height: Geometry.Height
    ) {
        self.init(
            llx: x,
            lly: y,
            urx: x + width,
            ury: y + height
        )
    }
}

extension Geometry.Orthotope where N == 2, Scalar: BinaryInteger {

    @inlinable
    public init(
        llx: Geometry.X,
        lly: Geometry.Y,
        urx: Geometry.X,
        ury: Geometry.Y
    ) {
        let halfWidth = (urx.underlying - llx.underlying) / 2
        let halfHeight = (ury.underlying - lly.underlying) / 2
        self.init(
            center: Geometry.Point(
                x: Geometry.X(llx.underlying + halfWidth),
                y: Geometry.Y(lly.underlying + halfHeight)
            ),
            halfExtents: Geometry.Size(
                width: Geometry.Width(halfWidth),
                height: Geometry.Height(halfHeight)
            )
        )
    }

    @inlinable
    public init(
        x: Geometry.X,
        y: Geometry.Y,
        width: Geometry.Width,
        height: Geometry.Height
    ) {
        self.init(
            llx: x,
            lly: y,
            urx: x + width,
            ury: y + height
        )
    }
}

extension Geometry.Orthotope where N == 2, Scalar: FloatingPoint {

    @inlinable
    public var midX: Geometry.X { center.x }

    @inlinable
    public var midY: Geometry.Y { center.y }

    @inlinable
    public var minX: Geometry.X { llx }

    @inlinable
    public var maxX: Geometry.X { urx }

    @inlinable
    public var minY: Geometry.Y { lly }

    @inlinable
    public var maxY: Geometry.Y { ury }

    @inlinable
    public var area: Geometry.Area { Geometry.area(of: self) }

    @inlinable
    public var perimeter: Geometry.Perimeter { Geometry.perimeter(of: self) }

    @inlinable
    public var diagonal: Geometry.Magnitude {
        let w = width
        let h = height
        return .init(sqrt(w * w + h * h))
    }
}

extension Geometry.Orthotope where N == 2, Scalar: FloatingPoint {

    @inlinable
    public var isEmpty: Bool {
        halfExtents.width.underlying <= 0 || halfExtents.height.underlying <= 0
    }

    @inlinable
    public func contains(_ point: Geometry.Point<2>) -> Bool {
        Geometry.contains(self, point: point)
    }

    @inlinable
    public func contains(_ other: Self) -> Bool {
        Geometry.contains(self, other)
    }

    @inlinable
    public func intersects(_ other: Self) -> Bool {
        Geometry.intersects(self, other)
    }
}

extension Geometry.Orthotope where N == 2, Scalar: FloatingPoint {

    @inlinable
    public func union(_ other: Self) -> Self {
        Geometry.union(self, other)
    }

    @inlinable
    public func intersection(_ other: Self) -> Self? {
        Geometry.intersection(self, other)
    }
}

extension Geometry.Orthotope where N == 2, Scalar: FloatingPoint {

    @inlinable
    public func corner(_ corner: Boundary.Corner) -> Geometry.Point<2> {
        switch corner {
        case .bottomLeft:
            return Geometry.Point(x: llx, y: lly)

        case .bottomRight:
            return Geometry.Point(x: urx, y: lly)

        case .topLeft:
            return Geometry.Point(x: llx, y: ury)

        case .topRight:
            return Geometry.Point(x: urx, y: ury)
        }
    }
}

extension Geometry.Orthotope where N == 2, Scalar: FloatingPoint {

    @inlinable
    public func with(llx newLlx: Geometry.X) -> Self {
        var copy = self
        copy.llx = newLlx
        return copy
    }

    @inlinable
    public func with(lly newLly: Geometry.Y) -> Self {
        var copy = self
        copy.lly = newLly
        return copy
    }

    @inlinable
    public func with(urx newUrx: Geometry.X) -> Self {
        var copy = self
        copy.urx = newUrx
        return copy
    }

    @inlinable
    public func with(ury newUry: Geometry.Y) -> Self {
        var copy = self
        copy.ury = newUry
        return copy
    }
}

extension Geometry.Orthotope where N == 2, Scalar: FloatingPoint {

    @inlinable
    public func translated(dx: Geometry.Width, dy: Geometry.Height) -> Self {
        Self(
            center: Geometry.Point(x: center.x + dx, y: center.y + dy),
            halfExtents: halfExtents
        )
    }

    @inlinable
    public func translated(by vector: Geometry.Vector<2>) -> Self {
        Self(center: center + vector, halfExtents: halfExtents)
    }

    @inlinable
    public func insetBy(dx: Geometry.Width, dy: Geometry.Height) -> Self {
        Self(
            center: center,
            halfExtents: Geometry.Size(
                width: halfExtents.width - dx,
                height: halfExtents.height - dy
            )
        )
    }

    @inlinable
    public func inset(by padding: Geometry.Size<1>) -> Self {
        insetBy(dx: padding.width, dy: padding.height)
    }

    @inlinable
    public func inset(by insets: Geometry.Insets) -> Self {
        Self(
            llx: llx + insets.leading,
            lly: lly + insets.bottom,
            urx: urx - insets.trailing,
            ury: ury - insets.top
        )
    }

    @inlinable
    public func scaled(by factor: Scale<1, Scalar>) -> Self {
        Self(
            center: center,
            halfExtents: Geometry.Size(
                width: halfExtents.width * factor,
                height: halfExtents.height * factor
            )
        )
    }
}

extension Geometry.Orthotope where N == 2, Scalar: FloatingPoint {

    @inlinable
    public func clamped(maxWidth: Geometry.Width) -> Self {
        guard width > maxWidth else { return self }
        var copy = self
        copy.width = maxWidth
        return copy
    }

    @inlinable
    public func clamped(maxHeight: Geometry.Height) -> Self {
        guard height > maxHeight else { return self }
        var copy = self
        copy.height = maxHeight
        return copy
    }
}

extension Geometry.Orthotope where N == 3, Scalar: FloatingPoint {

    @inlinable
    public var width: Geometry.Width {
        get { halfExtents.width * 2 }
        set { halfExtents.width = newValue / 2 }
    }

    @inlinable
    public var height: Geometry.Height {
        get { halfExtents.height * 2 }
        set { halfExtents.height = newValue / 2 }
    }

    @inlinable
    public var depth: Scalar {
        get { halfExtents.depth * 2 }
        set { halfExtents.dimensions[2] = newValue / 2 }
    }

    @inlinable
    public var volume: Scalar {
        let w = halfExtents.width.underlying * 2
        let h = halfExtents.height.underlying * 2
        let d = halfExtents.depth * 2
        return w * h * d
    }

    @inlinable
    public var surfaceArea: Scalar {
        let w = halfExtents.width.underlying * 2
        let h = halfExtents.height.underlying * 2
        let d = halfExtents.depth * 2
        return 2 * (w * h + w * d + h * d)
    }

    @inlinable
    public var diagonal: Geometry.Magnitude {
        let w = halfExtents.width.underlying * 2
        let h = halfExtents.height.underlying * 2
        let d = halfExtents.depth * 2
        return Geometry.Magnitude(
            Linear<Scalar, Space>.Magnitude((w * w + h * h + d * d).squareRoot())
        )
    }
}

extension Geometry.Orthotope {

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Orthotope<N> {
        Geometry<Result, Space>.Orthotope(
            center: try center.map(transform),
            halfExtents: try halfExtents.map(transform)
        )
    }
}

extension Geometry where Scalar: FloatingPoint {

    @inlinable
    public static func area(of rectangle: Orthotope<2>) -> Area {
        Area(rectangle.width.underlying * rectangle.height.underlying)
    }

    @inlinable
    public static func perimeter(of rectangle: Orthotope<2>) -> Perimeter {
        Perimeter((rectangle.width.underlying + rectangle.height.underlying) * 2)
    }

    @inlinable
    public static func contains(_ rectangle: Orthotope<2>, point: Point<2>) -> Bool {
        let dx = point.x.underlying - rectangle.center.x.underlying
        let dy = point.y.underlying - rectangle.center.y.underlying
        let hw = rectangle.halfExtents.width.underlying
        let hh = rectangle.halfExtents.height.underlying
        return dx >= -hw && dx <= hw && dy >= -hh && dy <= hh
    }

    @inlinable
    public static func contains(_ rectangle: Orthotope<2>, _ other: Orthotope<2>) -> Bool {
        other.llx >= rectangle.llx && other.urx <= rectangle.urx && other.lly >= rectangle.lly
            && other.ury <= rectangle.ury
    }

    @inlinable
    public static func intersects(_ rectangle1: Orthotope<2>, _ rectangle2: Orthotope<2>) -> Bool {
        rectangle1.llx <= rectangle2.urx && rectangle1.urx >= rectangle2.llx
            && rectangle1.lly <= rectangle2.ury && rectangle1.ury >= rectangle2.lly
    }

    @inlinable
    public static func union(_ rectangle1: Orthotope<2>, _ rectangle2: Orthotope<2>) -> Orthotope<2> {

        Orthotope<2>(
            llx: Swift.min(rectangle1.llx, rectangle2.llx),
            lly: Swift.min(rectangle1.lly, rectangle2.lly),
            urx: Swift.max(rectangle1.urx, rectangle2.urx),
            ury: Swift.max(rectangle1.ury, rectangle2.ury)
        )
    }

    @inlinable
    public static func intersection(
        _ rectangle1: Orthotope<2>,
        _ rectangle2: Orthotope<2>
    ) -> Orthotope<2>? {
        guard intersects(rectangle1, rectangle2) else { return nil }

        return Orthotope<2>(
            llx: Swift.max(rectangle1.llx, rectangle2.llx),
            lly: Swift.max(rectangle1.lly, rectangle2.lly),
            urx: Swift.min(rectangle1.urx, rectangle2.urx),
            ury: Swift.min(rectangle1.ury, rectangle2.ury)
        )
    }
}
