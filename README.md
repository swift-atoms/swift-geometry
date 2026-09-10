
## Layer and ownership

Geometry combines spatial quantities with sizes, insets, curvature and layout-facing geometry. It is a molecule; adapting its dependencies and implementation is deferred to the higher-layer pass.

Quantized geometry domains conform to Quantizer.Quantized. Grid validation and rounding belong to Quantizer; geometry retains the coordinate, displacement, and extent operations.

The legacy `Geometry.Size` remains a signed dimension vector during consumer
migration. It now delegates storage, equality, hashing and exact-count coding to
Vector; it is not an alias for the nonnegative finite Size atom. Empty dimensions
are supported by mapping and coding. Layout and document consumers must settle
signed offsets versus validated extents before the legacy spelling can retire.

Geometry.Insets directly aliases Inset<2, Scalar>. Named edges, signed arithmetic,
value semantics, mapping and coding belong to that atom. Edge values are scalars;
consumers explicitly supply any frame/unit interpretation. This migration uses the
atom's lower/upper encoding and canonical map order, not the old wrapper format.
