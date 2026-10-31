import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/money/money.dart';

/// In-memory identity manager for a pending goal-related financial transfer.
///
/// A failed operation keeps both its idempotency key and occurredAt timestamp
/// so a retry has the exact same financial fingerprint. Once the caller has
/// completed the operation and refreshed its projection, it must call
/// [markSucceeded] so a later intentional transfer gets a fresh identity.
class GoalTransferIdempotencyIdentity {
  const GoalTransferIdempotencyIdentity({
    required this.signature,
    required this.idempotencyKey,
    required this.occurredAt,
  });

  final String signature;
  final String idempotencyKey;
  final DateTime occurredAt;
}

class GoalTransferIdempotencyManager {
  GoalTransferIdempotencyManager({Uuid? uuid, DateTime Function()? clock})
    : _uuid = uuid ?? const Uuid(),
      _clock = clock ?? DateTime.now;

  final Uuid _uuid;
  final DateTime Function() _clock;
  final Map<String, GoalTransferIdempotencyIdentity> _pending = {};

  GoalTransferIdempotencyIdentity obtain({
    required String operationType,
    required String goalId,
    required String sourceAccountId,
    required String savingAccountId,
    required double amount,
  }) {
    final signature = jsonEncode(<Object?>[
      operationType,
      goalId,
      sourceAccountId,
      savingAccountId,
      Money.fromDouble(amount).toString(),
    ]);

    return _pending.putIfAbsent(
      signature,
      () => GoalTransferIdempotencyIdentity(
        signature: signature,
        idempotencyKey: '$operationType-${_uuid.v4()}',
        occurredAt: _clock(),
      ),
    );
  }

  void markSucceeded(GoalTransferIdempotencyIdentity identity) {
    final current = _pending[identity.signature];
    if (current?.idempotencyKey == identity.idempotencyKey) {
      _pending.remove(identity.signature);
    }
  }
}
