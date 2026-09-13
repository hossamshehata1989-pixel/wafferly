import '../../core/money/money.dart';
import '../account.dart';
import '../commitment.dart';
import '../enums/scheduled_action_state.dart';
import '../schedule_occurrence.dart';
import '../schedule_rule.dart';

/// Read-only projection of the current debt position and its next scheduled
/// payment. It does not own or persist financial truth.
final class DebtSummary {
  final Account liabilityAccount;
  final Money outstanding;
  final Commitment? nextPayment;
  final ScheduleRule? scheduleRule;
  final ScheduleOccurrence? occurrence;
  final ScheduledActionState? paymentState;

  const DebtSummary({
    required this.liabilityAccount,
    required this.outstanding,
    this.nextPayment,
    this.scheduleRule,
    this.occurrence,
    this.paymentState,
  });
}
