import '../interpretation/normalized_intent.dart';
import 'domain_guard_result.dart';

/// Validates immutable domain facts.
///
/// Examples:
/// - Account exists.
/// - Currency is supported.
/// - Goal exists.
/// - Commitment exists.
///
/// This stage MUST NOT evaluate business policies.
abstract interface class DomainGuard {
  Future<DomainGuardResult> validate(NormalizedIntent intent);
}
