#if Affine
    public import Numeric

    extension Geometry.Region.Sample where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// A disc's sample at a point `dx`, `dy` from its centre: the distance to its circle, and the direction away
        /// from the centre; at the centre itself, minus the radius and no direction. Written once for the renderer
        /// in pure Swift and a GPU's kernels.
        @inlinable
        @inline(__always)
        public static func ball(_ dx: Scalar, _ dy: Scalar, radius: Scalar) -> Self {
            let length = (dx * dx + dy * dy).squareRoot()
            guard length > 0 else { return Self(distance: -radius, x: 0, y: 0) }
            return Self(distance: length - radius, x: dx / length, y: dy / length)
        }

        /// A corner's radius as a box holds it: 0 for one that is not a number or below 0, and at most half the
        /// shorter side.
        @inlinable
        @inline(__always)
        public static func corner(_ radius: Scalar, halves x: Scalar, _ y: Scalar) -> Scalar {
            Swift.min(Swift.max(radius.isNaN ? 0 : radius, 0), Swift.min(x, y))
        }

        /// A superellipse's exponent as a box holds it: 2 for one that is not a number, and at least 1.
        @inlinable
        @inline(__always)
        public static func exponent(_ exponent: Scalar) -> Scalar {
            Swift.max(exponent.isNaN ? 2 : exponent, 1)
        }

        /// A box's sample at a point `dx`, `dy` from its centre, its half sides `halfX` and `halfY`, its corners
        /// rounded by `radius` (held by `corner(_:halves:_:)`): circular arcs, the exact distance; or with an
        /// `exponent`, quarters of a superellipse, as `Geometry.Superellipse` describes.
        @inlinable
        @inline(__always)
        public static func box(_ dx: Scalar, _ dy: Scalar, halfX: Scalar, halfY: Scalar, radius: Scalar, exponent: Scalar? = nil) -> Self {
            let round = corner(radius, halves: halfX, halfY)
            let sx: Scalar = dx < 0 ? -1 : 1
            let sy: Scalar = dy < 0 ? -1 : 1
            let qx = abs(dx) - (halfX - round)
            let qy = abs(dy) - (halfY - round)
            guard let exponent else {
                if qx > 0 || qy > 0 {
                    let ox = Swift.max(qx, 0)
                    let oy = Swift.max(qy, 0)
                    let length = (ox * ox + oy * oy).squareRoot()
                    return Self(distance: length - round, x: sx * ox / length, y: sy * oy / length)
                }
                return qx >= qy ? Self(distance: qx - round, x: sx, y: 0) : Self(distance: qy - round, x: 0, y: sy)
            }
            guard qx > 0, qy > 0, round > 0 else {
                return qx >= qy ? Self(distance: qx - round, x: sx, y: 0) : Self(distance: qy - round, x: 0, y: sy)
            }
            let n = Self.exponent(exponent)
            let scale = Swift.max(qx, qy)
            let ux = qx / scale
            let uy = qy / scale
            let px = Scalar._pow(ux, n)
            let py = Scalar._pow(uy, n)
            let norm = scale * Scalar._pow(px + py, 1 / n)
            let ratio = Scalar._pow(norm / scale, n - 1)
            let fx = px / ux / ratio
            let fy = py / uy / ratio
            let length = (fx * fx + fy * fy).squareRoot()
            guard length > 0, length.isFinite else { return Self(distance: norm - round, x: 0, y: 0) }
            return Self(distance: (norm - round) / length, x: sx * fx / length, y: sy * fy / length)
        }

        /// A polygon's sample at a point under the nonzero rule: the distance to its nearest edge, negative inside,
        /// and the direction away from that edge's nearest point. `edges` calls its visitor with each edge's ends;
        /// a polygon with no edges is infinitely far. Whether the point is inside is counted from the edges, unless
        /// `inside` says it, as a path whose sides curve between the edges' ends does.
        @inlinable
        @inline(__always)
        public static func polygon(
            _ x: Scalar,
            _ y: Scalar,
            inside: Bool? = nil,
            edges: (_ visit: (_ fromX: Scalar, _ fromY: Scalar, _ toX: Scalar, _ toY: Scalar) -> Void) -> Void
        ) -> Self {
            var best = Scalar.infinity
            var footX = x
            var footY = y
            var turns = 0
            edges { fromX, fromY, toX, toY in
                let runX = toX - fromX
                let runY = toY - fromY
                let square = runX * runX + runY * runY
                let t = square > 0 ? Swift.min(Swift.max(((x - fromX) * runX + (y - fromY) * runY) / square, 0), 1) : 0
                let nearX = fromX + t * runX
                let nearY = fromY + t * runY
                let away = (x - nearX) * (x - nearX) + (y - nearY) * (y - nearY)
                if away < best {
                    best = away
                    footX = nearX
                    footY = nearY
                }
                let hand = runX * (y - fromY) - (x - fromX) * runY
                if fromY <= y {
                    if toY > y, hand > 0 { turns &+= 1 }
                } else if toY <= y, hand < 0 {
                    turns &-= 1
                }
            }
            guard best.isFinite else { return Self(distance: .infinity, x: 0, y: 0) }
            let length = best.squareRoot()
            guard length > 0 else { return Self(distance: 0, x: 0, y: 0) }
            let sign: Scalar = (inside ?? (turns != 0)) ? -1 : 1
            return Self(distance: sign * length, x: sign * (x - footX) / length, y: sign * (y - footY) / length)
        }
    }
#endif
