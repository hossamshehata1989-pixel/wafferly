import 'dart:async';

import '../results/operation_result.dart';
import 'idempotency_record.dart';
import 'idempotency_store.dart';

/// Raised when an idempotency key is reused for a different or unverifiable
/// request.
final class IdempotencyConflictException implements Exception {
  final String key;
  final String message;

  const IdempotencyConflictException({
    required this.key,
    required this.message,
  });

  @override
  String toString() => 'IdempotencyConflictException($key): $message';
}

/// Coordinates idempotent execution and coalesces concurrent requests within
/// this guard instance.
final class IdempotencyGuard {
  final IdempotencyStore store;
  final Map<String, _InFlightExecution> _inFlight = {};

  IdempotencyGuard({required this.store});

  /// Runs [action] once for [key] and [requestFingerprint].
  ///
  /// Concurrent calls with the same key and fingerprint share the same Future.
  /// Reusing the key with another fingerprint is rejected. Only successful
  /// outcomes are persisted; failed/rejected outcomes may be retried.
  Future<OperationResult> run({
    required String key,
    required String requestFingerprint,
    required Future<OperationResult> Function() action,
  }) {
    if (key.trim().isEmpty) {
      return Future<OperationResult>.error(
        ArgumentError.value(key, 'key', 'Idempotency key cannot be empty.'),
      );
    }
    if (requestFingerprint.trim().isEmpty) {
      return Future<OperationResult>.error(
        ArgumentError.value(
          requestFingerprint,
          'requestFingerprint',
          'Request fingerprint cannot be empty.',
        ),
      );
    }

    final active = _inFlight[key];
    if (active != null) {
      if (active.requestFingerprint != requestFingerprint) {
        return Future<OperationResult>.error(
          IdempotencyConflictException(
            key: key,
            message: 'The key is already executing a different request.',
          ),
        );
      }
      return active.future;
    }

    // Reserve synchronously before starting any asynchronous store/action work.
    final completer = Completer<OperationResult>();
    final reservation = _InFlightExecution(
      requestFingerprint: requestFingerprint,
      future: completer.future,
    );
    _inFlight[key] = reservation;

    unawaited(
      _completeReservation(
        key: key,
        reservation: reservation,
        completer: completer,
        action: action,
      ),
    );

    return completer.future;
  }

  Future<void> _completeReservation({
    required String key,
    required _InFlightExecution reservation,
    required Completer<OperationResult> completer,
    required Future<OperationResult> Function() action,
  }) async {
    try {
      final cached = await store.findRecord(key);
      if (cached != null) {
        final cachedFingerprint = cached.requestFingerprint;
        if (cachedFingerprint == null) {
          throw IdempotencyConflictException(
            key: key,
            message:
                'A legacy record has no request fingerprint and cannot be '
                'safely replayed. Retry with a new idempotency key.',
          );
        }
        if (cachedFingerprint != reservation.requestFingerprint) {
          throw IdempotencyConflictException(
            key: key,
            message: 'The key was already used for a different request.',
          );
        }
        completer.complete(cached.result);
        return;
      }

      final result = await action();
      if (result is OperationSucceeded) {
        await store.saveRecord(
          IdempotencyRecord(
            key: key,
            requestFingerprint: reservation.requestFingerprint,
            result: result,
          ),
        );
      }
      completer.complete(result);
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    } finally {
      if (identical(_inFlight[key], reservation)) {
        _inFlight.remove(key);
      }
    }
  }
}

final class _InFlightExecution {
  final String requestFingerprint;
  final Future<OperationResult> future;

  const _InFlightExecution({
    required this.requestFingerprint,
    required this.future,
  });
}
