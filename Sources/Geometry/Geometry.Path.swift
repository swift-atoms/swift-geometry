public import Affine
public import Numeric
public import Tagged

extension Geometry {

    public struct Path {

        public var subpaths: [Subpath]

        @inlinable
        public init(subpaths: consuming [Subpath]) {
            self.subpaths = subpaths
        }
    }
}

extension Geometry.Path: Sendable where Scalar: Sendable {}
extension Geometry.Path: Equatable where Scalar: Equatable {}
extension Geometry.Path: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Path: Codable where Scalar: Codable {}
#endif

extension Geometry.Path {

    public struct Subpath {

        public var startPoint: Geometry.Point<2>

        public var segments: [Segment]

        public var isClosed: Bool

        @inlinable
        public init(
            startPoint: consuming Geometry.Point<2>,
            segments: consuming [Segment],
            isClosed: Bool = false
        ) {
            self.startPoint = startPoint
            self.segments = segments
            self.isClosed = isClosed
        }
    }
}

extension Geometry.Path.Subpath: Sendable where Scalar: Sendable {}
extension Geometry.Path.Subpath: Equatable where Scalar: Equatable {}
extension Geometry.Path.Subpath: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Path.Subpath: Codable where Scalar: Codable {}
#endif

extension Geometry.Path {

    public enum Segment {

        case line(Geometry.Line.Segment)

        case bezier(Geometry.Bezier)

        case arc(Geometry.Arc)

        case ellipticalArc(Geometry.Ellipse.Arc)
    }
}

extension Geometry.Path.Segment: Sendable where Scalar: Sendable {}
extension Geometry.Path.Segment: Equatable where Scalar: Equatable {}
extension Geometry.Path.Segment: Hashable where Scalar: Hashable {}

#if !hasFeature(Embedded)
    extension Geometry.Path.Segment: Codable where Scalar: Codable {}
#endif

extension Geometry.Path.Segment where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public var startPoint: Geometry.Point<2>? {
        switch self {
        case .line(let seg): return seg.start
        case .bezier(let bez): return bez.startPoint
        case .arc(let arc): return arc.startPoint
        case .ellipticalArc(let arc): return arc.startPoint
        }
    }

    @inlinable
    public var endPoint: Geometry.Point<2>? {
        switch self {
        case .line(let seg): return seg.end
        case .bezier(let bez): return bez.endPoint
        case .arc(let arc): return arc.endPoint
        case .ellipticalArc(let arc): return arc.endPoint
        }
    }
}

extension Array {

    @inlinable
    public init<Scalar: BinaryFloatingPoint & Numeric.Transcendental, Space>(
        segment: Geometry<Scalar, Space>.Path.Segment
    ) where Element == Geometry<Scalar, Space>.Bezier {
        switch segment {
        case .line(let seg):
            self = [.linear(from: seg.start, to: seg.end)]

        case .bezier(let bez):
            self = [bez]

        case .arc(let arc):
            self.init(arc: arc)

        case .ellipticalArc(let arc):
            self.init(ellipticalArc: arc)
        }
    }
}

extension Geometry.Path.Segment where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public func toBeziers() -> [Geometry.Bezier] { .init(segment: self) }
}

extension Geometry.Path {

    @inlinable
    public var isEmpty: Bool { subpaths.isEmpty }

    @inlinable
    public var segmentCount: Int {
        subpaths.reduce(0) { $0 + $1.segments.count }
    }
}

extension Array where Element: RangeReplaceableCollection {

    @inlinable
    public init<Scalar: BinaryFloatingPoint & Numeric.Transcendental, Space>(
        path: Geometry<Scalar, Space>.Path
    ) where Element == [Geometry<Scalar, Space>.Bezier] {
        self = path.subpaths.map { subpath in
            var beziers = subpath.segments.flatMap { [Geometry<Scalar, Space>.Bezier](segment: $0) }
            if subpath.isClosed, let last = beziers.last?.endPoint {
                if last != subpath.startPoint {
                    beziers.append(.linear(from: last, to: subpath.startPoint))
                }
            }
            return beziers
        }
    }
}

extension Geometry.Path where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public func toBeziers() -> [[Geometry.Bezier]] { .init(path: self) }

    @inlinable
    public var boundingBox: Geometry.Rectangle? {

        let allBeziers = toBeziers().flatMap { $0 }
        guard let first = allBeziers.first?.boundingBoxConservative else { return nil }
        return allBeziers.dropFirst().reduce(first) { rect, bez in
            guard let bezRect = bez.boundingBoxConservative else { return rect }
            return rect.union(bezRect)
        }
    }
}

extension Geometry.Path.Subpath {

    @inlinable
    public var isEmpty: Bool { segments.isEmpty }
}

extension Geometry.Path.Subpath where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public var endPoint: Geometry.Point<2>? {
        segments.last?.endPoint ?? startPoint
    }
}

extension Geometry.Path.Subpath where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

    @inlinable
    public func length(bezierSegments: Int = 100) -> Geometry.ArcLength {
        var total: Scalar = .zero
        for segment in segments {
            switch segment {
            case .line(let seg):
                total += seg.length.underlying

            case .bezier(let bez):
                total += bez.length(segments: bezierSegments).underlying

            case .arc(let arc):
                total += arc.length.underlying

            case .ellipticalArc(let arc):
                total += arc.length(segments: bezierSegments).underlying
            }
        }
        if isClosed, let end = endPoint, end != startPoint {
            total += end.distance(to: startPoint).underlying
        }
        return .init(_unchecked: total)
    }
}

extension Geometry.Path {

    @inlinable
    public static func polygon(vertices: [Geometry.Point<2>]) -> Self? {
        guard vertices.count >= 3 else { return nil }
        var segments: [Segment] = []
        for i in vertices.indices.dropLast() {
            segments.append(.line(.init(start: vertices[i], end: vertices[i + 1])))
        }
        return Self(subpaths: [
            .init(startPoint: vertices[0], segments: segments, isClosed: true)
        ])
    }

    @inlinable
    public static func polyline(vertices: [Geometry.Point<2>]) -> Self? {
        guard vertices.count >= 2 else { return nil }
        var segments: [Segment] = []
        for i in vertices.indices.dropLast() {
            segments.append(.line(.init(start: vertices[i], end: vertices[i + 1])))
        }
        return Self(subpaths: [
            .init(startPoint: vertices[0], segments: segments, isClosed: false)
        ])
    }
}

extension Geometry.Path.Segment {

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Path.Segment {
        switch self {
        case .line(let seg):
            return .line(try seg.map(transform))

        case .bezier(let bez):
            return .bezier(try bez.map(transform))

        case .arc(let arc):
            return .arc(try arc.map(transform))

        case .ellipticalArc(let arc):
            return .ellipticalArc(try arc.map(transform))
        }
    }
}

extension Geometry.Path.Subpath {

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Path.Subpath {
        .init(
            startPoint: try startPoint.map(transform),
            segments: try segments.map {
                (
                    segment: Geometry<Scalar, Space>.Path.Segment
                ) throws(E) -> Geometry<Result, Space>.Path.Segment in
                try segment.map(transform)
            },
            isClosed: isClosed
        )
    }
}

extension Geometry.Path {

    @inlinable
    public func map<Result, E: Swift.Error>(
        _ transform: (Scalar) throws(E) -> Result
    ) throws(E) -> Geometry<Result, Space>.Path {
        .init(
            subpaths: try subpaths.map {
                (
                    subpath: Geometry<Scalar, Space>.Path.Subpath
                ) throws(E) -> Geometry<Result, Space>.Path.Subpath in
                try subpath.map(transform)
            }
        )
    }
}
