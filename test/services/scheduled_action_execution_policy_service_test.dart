import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/enums/scheduled_action_execution_policy.dart';
import '../../lib/services/scheduled_action_execution_policy_service.dart';

void main() {
  const service = ScheduledActionExecutionPolicyService();

  group('ScheduledActionExecutionPolicyService', () {
    test('reminderOnly never crosses the execution boundary', () {
      expect(
        service.canCreateTransaction(
          policy: ScheduledActionExecutionPolicy.reminderOnly,
        ),
        isFalse,
      );
    });

    test('confirmBeforeCreate requires explicit confirmation', () {
      expect(
        service.canCreateTransaction(
          policy: ScheduledActionExecutionPolicy.confirmBeforeCreate,
        ),
        isFalse,
      );
      expect(
        service.canCreateTransaction(
          policy: ScheduledActionExecutionPolicy.confirmBeforeCreate,
          userConfirmed: true,
        ),
        isTrue,
      );
    });

    test('autoCreate allows crossing the policy boundary', () {
      expect(
        service.canCreateTransaction(
          policy: ScheduledActionExecutionPolicy.autoCreate,
        ),
        isTrue,
      );
    });
  });
}
