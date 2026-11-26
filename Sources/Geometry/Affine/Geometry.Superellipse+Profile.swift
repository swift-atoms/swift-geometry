#if Affine
    public import Numeric
    public import Vector

    extension Geometry.Superellipse where Scalar: BinaryFloatingPoint & Numeric.Transcendental {

        /// How high a superellipse's quarter stands `inward` from its foot: `thickness` times (1 − vᵖ)^(1/p) for
        /// v = 1 − inward / rim and p the exponent held as `Region.Sample.exponent(_:)`; upright at the foot, level
        /// with no slope from the rim on, where it is `thickness`, and 0 at the foot and outside. A glass pane's top
        /// stands so, on the CPU and on a GPU alike.
        @inlinable
        @inline(__always)
        public static func height(_ inward: Scalar, thickness: Scalar, rim: Scalar, exponent: Scalar) -> Scalar {
            guard inward > 0, thickness > 0 else { return 0 }
            guard rim > 0, inward < rim else { return thickness }
            let p = Geometry.Region.Sample.exponent(exponent)
            let v = 1 - inward / rim
            if p == 2 { return thickness * (1 - v * v).squareRoot() }
            return thickness * Scalar._pow(Swift.max(1 - Scalar._pow(v, p), 0), 1 / p)
        }

        /// How fast `height(_:thickness:rim:exponent:)` rises going in: `thickness / rim` · vᵖ⁻¹ · (1 − vᵖ)^(1/p − 1);
        /// 0 from the rim on and infinite at the foot. Closer to the foot than the square root of the number type's
        /// precision, as a share of the rim, 1 − vᵖ is taken as p · inward / rim, its first order, which is as close
        /// there as the difference itself, whose digits are lost.
        @inlinable
        @inline(__always)
        public static func slope(_ inward: Scalar, thickness: Scalar, rim: Scalar, exponent: Scalar) -> Scalar {
            guard thickness > 0, rim > 0, inward < rim else { return 0 }
            guard inward > 0 else { return .infinity }
            let p = Geometry.Region.Sample.exponent(exponent)
            let v = 1 - inward / rim
            let power = Scalar._pow(v, p)
            let tiny: Scalar = 1e-12
            let share = inward / rim
            let rest = Swift.max(share < Scalar.ulpOfOne.squareRoot() ? p * share : 1 - power, tiny)
            return thickness / rim * power / Swift.max(v, tiny) * Scalar._pow(rest, 1 / p - 1)
        }

        /// The unit normal of a top of a slope over a region whose sample has the gradient `gx`, `gy`, where x runs
        /// right, y down in the region and up in the result, and z toward the eye: (s·gx, −s·gy, 1) at unit length,
        /// or upright, (gx, −gy, 0), where the slope is infinite, and facing the eye where there is no gradient.
        @inlinable
        @inline(__always)
        public static func normal(slope s: Scalar, _ gx: Scalar, _ gy: Scalar) -> Vector<3, Scalar> {
            guard s.isFinite else {
                let length = (gx * gx + gy * gy).squareRoot()
                guard length > 0 else { return Vector([0, 0, 1]) }
                return Vector([gx / length, -gy / length, 0])
            }
            let x = s * gx
            let y = -s * gy
            let length = (x * x + y * y + 1).squareRoot()
            return Vector([x / length, y / length, 1 / length])
        }
    }
#endif
