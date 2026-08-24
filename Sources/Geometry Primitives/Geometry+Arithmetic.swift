public import Dimension_Primitives
import Linear_Primitives
import Real_Primitives

@inlinable
public func * <Scalar: FloatingPoint, Space, let N: Int>(
    lhs: Geometry<Scalar, Space>.Size<N>,
    rhs: Scale<1, Scalar>
) -> Geometry<Scalar, Space>.Size<N> {
    var result = lhs.dimensions
    (0..<N).forEach { i in
        result[i] = lhs.dimensions[i] * rhs.value
    }
    return Geometry<Scalar, Space>.Size<N>(result)
}

@inlinable
public func * <Scalar: FloatingPoint, Space, let N: Int>(
    lhs: Scale<1, Scalar>,
    rhs: Geometry<Scalar, Space>.Size<N>
) -> Geometry<Scalar, Space>.Size<N> {
    rhs * lhs
}

@inlinable
public func / <Scalar: FloatingPoint, Space, let N: Int>(
    lhs: Geometry<Scalar, Space>.Size<N>,
    rhs: Scale<1, Scalar>
) -> Geometry<Scalar, Space>.Size<N> {
    var result = lhs.dimensions
    (0..<N).forEach { i in
        result[i] = lhs.dimensions[i] / rhs.value
    }
    return Geometry<Scalar, Space>.Size<N>(result)
}

@_disfavoredOverload
@inlinable
public func * <Scalar: FloatingPoint, Space, let N: Int>(
    lhs: Geometry<Scalar, Space>.Size<N>,
    rhs: Scale<N, Scalar>
) -> Geometry<Scalar, Space>.Size<N> {
    var result = lhs.dimensions
    (0..<N).forEach { i in
        result[i] = lhs.dimensions[i] * rhs.factors[i]
    }
    return Geometry<Scalar, Space>.Size<N>(result)
}

@_disfavoredOverload
@inlinable
public func * <Scalar: FloatingPoint, Space, let N: Int>(
    lhs: Scale<N, Scalar>,
    rhs: Geometry<Scalar, Space>.Size<N>
) -> Geometry<Scalar, Space>.Size<N> {
    rhs * lhs
}

@_disfavoredOverload
@inlinable
public func / <Scalar: FloatingPoint, Space, let N: Int>(
    lhs: Geometry<Scalar, Space>.Size<N>,
    rhs: Scale<N, Scalar>
) -> Geometry<Scalar, Space>.Size<N> {
    var result = lhs.dimensions
    (0..<N).forEach { i in
        result[i] = lhs.dimensions[i] / rhs.factors[i]
    }
    return Geometry<Scalar, Space>.Size<N>(result)
}

extension Geometry.Depth where Scalar: SignedNumeric {

    @inlinable
    public static prefix func - (value: borrowing Self) -> Self {
        Self(-value.value)
    }
}

extension Geometry.Depth where Scalar: AdditiveArithmetic {

    @inlinable
    @_disfavoredOverload
    public static func + (lhs: borrowing Self, rhs: borrowing Self) -> Self {
        Self(lhs.value + rhs.value)
    }

    @inlinable
    @_disfavoredOverload
    public static func - (lhs: borrowing Self, rhs: borrowing Self) -> Self {
        Self(lhs.value - rhs.value)
    }
}

extension Geometry.Depth: Comparable where Scalar: Comparable {

    @inlinable
    @_disfavoredOverload
    public static func < (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        lhs.value < rhs.value
    }
}

extension Geometry.Insets where Scalar: AdditiveArithmetic {

    @inlinable
    @_disfavoredOverload
    public static func + (lhs: borrowing Self, rhs: borrowing Self) -> Self {
        Self(
            top: lhs.top + rhs.top,
            leading: lhs.leading + rhs.leading,
            bottom: lhs.bottom + rhs.bottom,
            trailing: lhs.trailing + rhs.trailing
        )
    }

    @inlinable
    @_disfavoredOverload
    public static func - (lhs: borrowing Self, rhs: borrowing Self) -> Self {
        Self(
            top: lhs.top - rhs.top,
            leading: lhs.leading - rhs.leading,
            bottom: lhs.bottom - rhs.bottom,
            trailing: lhs.trailing - rhs.trailing
        )
    }
}

extension Geometry.Insets where Scalar: SignedNumeric {

    @inlinable
    @_disfavoredOverload
    public static prefix func - (value: borrowing Self) -> Self {
        Self(
            top: -value.top,
            leading: -value.leading,
            bottom: -value.bottom,
            trailing: -value.trailing
        )
    }
}

extension Geometry.Size where Scalar: AdditiveArithmetic {

    @inlinable
    @_disfavoredOverload
    public static func + (lhs: borrowing Self, rhs: borrowing Self) -> Self {
        var result = InlineArray<N, Scalar>(repeating: .zero)
        for i in 0..<N {
            result[i] = lhs.dimensions[i] + rhs.dimensions[i]
        }
        return Self(result)
    }

    @inlinable
    @_disfavoredOverload
    public static func - (lhs: borrowing Self, rhs: borrowing Self) -> Self {
        var result = InlineArray<N, Scalar>(repeating: .zero)
        for i in 0..<N {
            result[i] = lhs.dimensions[i] - rhs.dimensions[i]
        }
        return Self(result)
    }
}

extension Geometry.Size where Scalar: SignedNumeric {

    @inlinable
    @_disfavoredOverload
    public static prefix func - (value: borrowing Self) -> Self {
        var result = InlineArray<N, Scalar>(repeating: .zero)
        for i in 0..<N {
            result[i] = -value.dimensions[i]
        }
        return Self(result)
    }
}

@_disfavoredOverload
@inlinable
public func / <Scalar: FloatingPoint, Space>(
    lhs: Geometry<Scalar, Space>.Height,
    rhs: Geometry<Scalar, Space>.Height
) -> Scale<1, Scalar> {
    Scale(lhs.underlying / rhs.underlying)
}

@_disfavoredOverload
@inlinable
public func / <Scalar: FloatingPoint, Space>(
    lhs: Geometry<Scalar, Space>.Width,
    rhs: Geometry<Scalar, Space>.Width
) -> Scale<1, Scalar> {
    Scale(lhs.underlying / rhs.underlying)
}

@_disfavoredOverload
@inlinable
public func / <Scalar: FloatingPoint, Space>(
    lhs: Linear<Scalar, Space>.Magnitude,
    rhs: Linear<Scalar, Space>.Magnitude
) -> Scale<1, Scalar> {
    Scale(lhs.underlying / rhs.underlying)
}

@_disfavoredOverload
@inlinable
public func + <Scalar: AdditiveArithmetic, Space>(
    lhs: Geometry<Scalar, Space>.Height,
    rhs: Geometry<Scalar, Space>.Height
) -> Geometry<Scalar, Space>.Height {
    Geometry<Scalar, Space>.Height(lhs.underlying + rhs.underlying)
}

@_disfavoredOverload
@inlinable
public func - <Scalar: AdditiveArithmetic, Space>(
    lhs: Geometry<Scalar, Space>.Height,
    rhs: Geometry<Scalar, Space>.Height
) -> Geometry<Scalar, Space>.Height {
    Geometry<Scalar, Space>.Height(lhs.underlying - rhs.underlying)
}

@_disfavoredOverload
@inlinable
public func + <Scalar: AdditiveArithmetic, Space>(
    lhs: Geometry<Scalar, Space>.Width,
    rhs: Geometry<Scalar, Space>.Width
) -> Geometry<Scalar, Space>.Width {
    Geometry<Scalar, Space>.Width(lhs.underlying + rhs.underlying)
}

@_disfavoredOverload
@inlinable
public func - <Scalar: AdditiveArithmetic, Space>(
    lhs: Geometry<Scalar, Space>.Width,
    rhs: Geometry<Scalar, Space>.Width
) -> Geometry<Scalar, Space>.Width {
    Geometry<Scalar, Space>.Width(lhs.underlying - rhs.underlying)
}

@inlinable
public func + <Scalar: BinaryFloatingPoint, Space: Numeric.Quantized>(
    lhs: Geometry<Scalar, Space>.Height,
    rhs: Geometry<Scalar, Space>.Height
) -> Geometry<Scalar, Space>.Height where Space.Scalar == Scalar {
    ._quantize(lhs.underlying + rhs.underlying, in: Space.self)
}

@inlinable
public func - <Scalar: BinaryFloatingPoint, Space: Numeric.Quantized>(
    lhs: Geometry<Scalar, Space>.Height,
    rhs: Geometry<Scalar, Space>.Height
) -> Geometry<Scalar, Space>.Height where Space.Scalar == Scalar {
    ._quantize(lhs.underlying - rhs.underlying, in: Space.self)
}

@inlinable
public func + <Scalar: BinaryFloatingPoint, Space: Numeric.Quantized>(
    lhs: Geometry<Scalar, Space>.Width,
    rhs: Geometry<Scalar, Space>.Width
) -> Geometry<Scalar, Space>.Width where Space.Scalar == Scalar {
    ._quantize(lhs.underlying + rhs.underlying, in: Space.self)
}

@inlinable
public func - <Scalar: BinaryFloatingPoint, Space: Numeric.Quantized>(
    lhs: Geometry<Scalar, Space>.Width,
    rhs: Geometry<Scalar, Space>.Width
) -> Geometry<Scalar, Space>.Width where Space.Scalar == Scalar {
    ._quantize(lhs.underlying - rhs.underlying, in: Space.self)
}

@_disfavoredOverload
@inlinable
public func * <Scalar: FloatingPoint, Space>(
    lhs: Geometry<Scalar, Space>.Height,
    rhs: Scale<1, Scalar>
) -> Geometry<Scalar, Space>.Height {
    Geometry<Scalar, Space>.Height(lhs.underlying * rhs.value)
}

@_disfavoredOverload
@inlinable
public func * <Scalar: FloatingPoint, Space>(
    lhs: Scale<1, Scalar>,
    rhs: Geometry<Scalar, Space>.Height
) -> Geometry<Scalar, Space>.Height {
    rhs * lhs
}

@_disfavoredOverload
@inlinable
public func * <Scalar: FloatingPoint, Space>(
    lhs: Geometry<Scalar, Space>.Width,
    rhs: Scale<1, Scalar>
) -> Geometry<Scalar, Space>.Width {
    Geometry<Scalar, Space>.Width(lhs.underlying * rhs.value)
}

@_disfavoredOverload
@inlinable
public func * <Scalar: FloatingPoint, Space>(
    lhs: Scale<1, Scalar>,
    rhs: Geometry<Scalar, Space>.Width
) -> Geometry<Scalar, Space>.Width {
    rhs * lhs
}

@inlinable
public func * <Scalar: BinaryFloatingPoint, Space: Numeric.Quantized>(
    lhs: Geometry<Scalar, Space>.Height,
    rhs: Scale<1, Scalar>
) -> Geometry<Scalar, Space>.Height where Space.Scalar == Scalar {
    ._quantize(lhs.underlying * rhs.value, in: Space.self)
}

@inlinable
public func * <Scalar: BinaryFloatingPoint, Space: Numeric.Quantized>(
    lhs: Scale<1, Scalar>,
    rhs: Geometry<Scalar, Space>.Height
) -> Geometry<Scalar, Space>.Height where Space.Scalar == Scalar {
    rhs * lhs
}

@inlinable
public func * <Scalar: BinaryFloatingPoint, Space: Numeric.Quantized>(
    lhs: Geometry<Scalar, Space>.Width,
    rhs: Scale<1, Scalar>
) -> Geometry<Scalar, Space>.Width where Space.Scalar == Scalar {
    ._quantize(lhs.underlying * rhs.value, in: Space.self)
}

@inlinable
public func * <Scalar: BinaryFloatingPoint, Space: Numeric.Quantized>(
    lhs: Scale<1, Scalar>,
    rhs: Geometry<Scalar, Space>.Width
) -> Geometry<Scalar, Space>.Width where Space.Scalar == Scalar {
    rhs * lhs
}
