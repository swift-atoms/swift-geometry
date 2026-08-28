public import Pair

public enum Curvature: Sendable, Hashable, Codable, CaseIterable {

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

extension Curvature {

    public typealias Value<Payload> = Pair<Curvature, Payload>
}
