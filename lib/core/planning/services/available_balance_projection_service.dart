import '../ports/allocation_repository.dart';
import '../projections/available_balance_projection.dart';
import '../value_objects/allocation_status.dart';

/// ===============================================================
/// AvailableBalanceProjectionService
/// ===============================================================
///
/// Read-side service for account reservation state.
///
/// Responsibilities:
/// - Read Allocations through the Planning boundary.
/// - Calculate the currently reserved amount.
/// - Derive available balance from the supplied account balance.
///
/// It does NOT:
/// - Create or mutate Allocations.
/// - Access Hive directly.
/// - Calculate account balance from Transactions.
/// - Depend on the legacy ReservedMoneyService.
///
/// Formula:
///
///   reserved  = SUM(active Allocations for account)
///   available = balance - reserved
///
/// ===============================================================
final class AvailableBalanceProjectionService {
  const AvailableBalanceProjectionService({
    required AllocationRepository allocationRepository,
  }) : _allocationRepository = allocationRepository;

  final AllocationRepository _allocationRepository;

  /// Builds the current AvailableBalanceProjection for an account.
  ///
  /// [balance] must be the current Account balance supplied by the
  /// Account/Balance side.
  Future<AvailableBalanceProjection> project({
    required String accountId,
    required double balance,
  }) async {
    final allocations = await _allocationRepository.findByAccount(accountId);

    final reserved = allocations
        .where((allocation) => allocation.status == AllocationStatus.active)
        .fold<double>(0, (total, allocation) => total + allocation.amount);

    return AvailableBalanceProjection(
      accountId: accountId,
      balance: balance,
      reserved: reserved,
      available: balance - reserved,
    );
  }
}
