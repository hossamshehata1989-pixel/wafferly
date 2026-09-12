import '../models/enums/scheduled_action_execution_policy.dart';

/// Decides whether a scheduled action is allowed to cross the execution
/// boundary. It does not create a transaction or invoke the financial engine.
class ScheduledActionExecutionPolicyService {
  const ScheduledActionExecutionPolicyService();

  bool canCreateTransaction({
    required ScheduledActionExecutionPolicy policy,
    bool userConfirmed = false,
  }) {
    switch (policy) {
      case ScheduledActionExecutionPolicy.reminderOnly:
        return false;
      case ScheduledActionExecutionPolicy.confirmBeforeCreate:
        return userConfirmed;
      case ScheduledActionExecutionPolicy.autoCreate:
        return true;
    }
  }
}
