/// ===============================================================
/// AllocationIdGenerator
/// ===============================================================
///
/// Generates unique Allocation identifiers.
///
/// The Planning Engine depends only on this abstraction.
/// Infrastructure provides the actual implementation.
///
/// ===============================================================
abstract interface class AllocationIdGenerator {
  const AllocationIdGenerator();

  String next();
}
