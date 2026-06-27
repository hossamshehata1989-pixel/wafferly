import 'enums/scheduled_action_kind.dart';
import 'enums/scheduled_action_state.dart';

class ScheduledAction {
  final String id;

  final ScheduledActionKind kind;

  final ScheduledActionState state;

  final String title;

  final String subtitle;

  final double amount;

  final DateTime dueDate;

  final String? sourceAccountId;

  final String? destinationAccountId;

  final String? commitmentId;

  final String? liabilityAccountId;

  const ScheduledAction({
    required this.id,
    required this.kind,
    required this.state,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dueDate,
    this.sourceAccountId,
    this.destinationAccountId,
    this.commitmentId,
    this.liabilityAccountId,
  });
}
