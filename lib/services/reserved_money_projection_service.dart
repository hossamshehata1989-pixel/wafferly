import '../core/planning/entities/allocation.dart';
import '../core/planning/ports/allocation_repository.dart';
import '../core/planning/value_objects/allocation_status.dart';
import '../models/goal.dart';
import '../models/reserved_money_projection.dart';
import 'account_service.dart';
import 'goal_service.dart';

/// Read-side projection for the global Reserved Money screen.
///
/// The source of truth for CURRENT reservations is the Planning Engine's
/// active Allocation state. Allocation is intentionally treated only as
/// operational planning state, not as financial history.
class ReservedMoneyProjectionService {
  ReservedMoneyProjectionService({
    required AllocationRepository allocationRepository,
    GoalService? goalService,
    AccountService? accountService,
  })  : _allocationRepository = allocationRepository,
        _goalService = goalService ?? GoalService(),
        _accountService = accountService ?? AccountService();

  final AllocationRepository _allocationRepository;
  final GoalService _goalService;
  final AccountService _accountService;

  Future<ReservedMoneyProjection> getProjection() async {
    final allocations = await _allocationRepository.findActive();

    final active = allocations
        .where((allocation) => allocation.status == AllocationStatus.active)
        .where((allocation) => allocation.amount > 0)
        .toList();

    final items = <ReservedMoneyItem>[];

    for (final allocation in active) {
      final sourceType = allocation.sourceType.name;

      items.add(
        ReservedMoneyItem(
          allocationId: allocation.id,
          sourceId: allocation.sourceId,
          sourceType: sourceType,
          sourceName: _resolveSourceName(
            sourceType: sourceType,
            sourceId: allocation.sourceId,
          ),
          accountId: allocation.accountId,
          accountName: _resolveAccountName(allocation.accountId),
          amount: allocation.amount,
          createdAt: allocation.createdAt,
        ),
      );
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalReserved = items.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    final categories = _buildCategories(items);
    final accounts = _buildAccounts(items);

    return ReservedMoneyProjection(
      totalReserved: totalReserved,
      items: List.unmodifiable(items),
      categories: List.unmodifiable(categories),
      accounts: List.unmodifiable(accounts),
    );
  }

  List<ReservedMoneyCategory> _buildCategories(
    List<ReservedMoneyItem> items,
  ) {
    final grouped = <String, List<ReservedMoneyItem>>{};

    for (final item in items) {
      grouped.putIfAbsent(item.sourceType, () => <ReservedMoneyItem>[]).add(item);
    }

    final categories = grouped.entries.map((entry) {
      final rows = List<ReservedMoneyItem>.from(entry.value);
      rows.sort((a, b) => b.amount.compareTo(a.amount));

      final total = rows.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );

      return ReservedMoneyCategory(
        key: entry.key,
        title: _categoryTitle(entry.key),
        items: List.unmodifiable(rows),
        total: total,
      );
    }).toList();

    categories.sort((a, b) => b.total.compareTo(a.total));
    return categories;
  }

  List<ReservedMoneyAccountSummary> _buildAccounts(
    List<ReservedMoneyItem> items,
  ) {
    final grouped = <String, ReservedMoneyAccountSummary>{};

    for (final item in items) {
      final current = grouped[item.accountId];

      if (current == null) {
        grouped[item.accountId] = ReservedMoneyAccountSummary(
          accountId: item.accountId,
          accountName: item.accountName,
          reserved: item.amount,
        );
      } else {
        grouped[item.accountId] = ReservedMoneyAccountSummary(
          accountId: current.accountId,
          accountName: current.accountName,
          reserved: current.reserved + item.amount,
        );
      }
    }

    final result = grouped.values.toList();
    result.sort((a, b) => b.reserved.compareTo(a.reserved));
    return result;
  }

  String _resolveSourceName({
    required String sourceType,
    required String sourceId,
  }) {
    if (sourceType == 'goal') {
      final goal = _goalService.getById(sourceId);
      return goal?.title ?? 'Unknown Goal';
    }

    // Budget / manual / future planning sources will get their concrete
    // name resolver when their current source model is wired into the
    // Planning read side. We deliberately do not invent a second source
    // of truth here.
    return sourceId;
  }

  String _resolveAccountName(String accountId) {
    return _accountService.getAccountById(accountId)?.name ?? 'Unknown Account';
  }

  String _categoryTitle(String sourceType) {
    switch (sourceType) {
      case 'goal':
        return 'Goals';
      case 'budget':
        return 'Budgets';
      case 'manual':
        return 'Manual Reserves';
      case 'commitment':
        return 'Commitments';
      default:
        return _titleCase(sourceType);
    }
  }

  String _titleCase(String value) {
    if (value.trim().isEmpty) return value;

    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
