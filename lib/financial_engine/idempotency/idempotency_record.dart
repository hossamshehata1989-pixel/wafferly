import '../results/operation_result.dart';

/// A successful result associated with one idempotency key and request.
///
/// [requestFingerprint] is null only for records written by the legacy v1
/// store format. Such records can be read for compatibility, but cannot be
/// safely replayed by the fingerprint-aware guard.
final class IdempotencyRecord {
  final String key;
  final String? requestFingerprint;
  final OperationResult result;

  const IdempotencyRecord({
    required this.key,
    required this.result,
    this.requestFingerprint,
  });

  bool get hasVerifiableFingerprint => requestFingerprint != null;
}
