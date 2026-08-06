import '../entities/allocation.dart';

/// ===============================================================
/// AllocationRepository
/// ===============================================================
///
/// Persistence contract for Allocation entities.
///
/// The Planning Engine depends only on this contract.
/// Infrastructure provides the concrete implementation.
///
/// ADR References:
/// - ADR-028 Allocation Contract
///
/// ===============================================================
abstract interface class AllocationRepository {
  /// Creates a new Allocation.
  Future<void> create(Allocation allocation);

  /// Updates an existing Allocation.
  Future<void> update(Allocation allocation);

  /// Finds an Allocation by its identifier.
  Future<Allocation?> findById(String allocationId);

  /// Returns all Allocations belonging to a planning source.
  Future<List<Allocation>> findBySource(String sourceId);

  /// Returns all Allocations reserved from an account.
  Future<List<Allocation>> findByAccount(String accountId);

  /// Returns all active Allocations.
  Future<List<Allocation>> findActive();

  /// Returns whether an allocation already exists
  /// for the specified planning source.
  /// Deletes an Allocation.
  ///
  /// This should rarely be used in production.
  /// Business operations should prefer changing Allocation status.
  Future<void> delete(String allocationId);

  Future<Allocation?> findCurrentBySource(String sourceId);
}
