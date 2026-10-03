public enum Curvature: Sendable, Hashable, CaseIterable {

    case convex

    case concave
}

extension Curvature {

    @inlinable
    public var opposite: Curvature {
        switch self {
        case .convex: return .concave
        case .concave: return .convex
        }
    }

    @inlinable
    public static prefix func ! (value: Curvature) -> Curvature {
        value.opposite
    }
}

#if !hasFeature(Embedded)
    extension Curvature: Codable {}
#endif
