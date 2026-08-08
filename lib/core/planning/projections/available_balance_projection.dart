import 'package:flutter/foundation.dart';

/// ===============================================================
/// AvailableBalanceProjection
/// ===============================================================
///
/// Read model representing the financial availability of an account
/// after considering active Planning allocations.
///
/// This is a projection only.
/// It does not own or mutate financial or planning state.
///
/// Derived values:
///   reserved  = SUM(active Allocations for account)
///   available = balance - reserved
///
/// ===============================================================
@immutable
final class AvailableBalanceProjection {
  const AvailableBalanceProjection({
    required this.accountId,
    required this.balance,
    required this.reserved,
    required this.available,
  });

  /// Account this projection belongs to.
  final String accountId;

  /// Current account balance from the Account/Balance side.
  final double balance;

  /// Total amount currently reserved by active Planning Allocations.
  final double reserved;

  /// Amount currently available after reservations.
  final double available;
}
