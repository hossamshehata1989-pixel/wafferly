import '../interpretation/normalized_intent.dart';
import 'domain_guard.dart';
import 'domain_guard_result.dart';

final class DomainGuardPipeline {
  final List<DomainGuard> _guards;

  const DomainGuardPipeline({List<DomainGuard> guards = const []})
    : _guards = guards;

  Future<DomainGuardResult> validate(NormalizedIntent intent) async {
    for (final guard in _guards) {
      final result = await guard.validate(intent);

      if (result is DomainViolation) {
        return result;
      }
    }

    return const DomainGuardPassed();
  }
}
