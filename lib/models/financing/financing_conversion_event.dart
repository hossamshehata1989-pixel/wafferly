import 'package:hive/hive.dart';

part 'financing_conversion_event.g.dart';

/// Durable financing-domain record for one Credit Card charge conversion.
///
/// This is NOT financial truth and is NOT the Financial Engine idempotency
/// store. It exists only to make financing conversion recovery deterministic.
@HiveType(typeId: 114)
class FinancingConversionEvent {
  @HiveField(0)
  final String conversionId;

  @HiveField(1)
  final String originChargeId;

  @HiveField(2)
  final String contractId;

  @HiveField(3)
  final String scheduleId;

  @HiveField(4)
  final String scheduleRuleId;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  const FinancingConversionEvent({
    required this.conversionId,
    required this.originChargeId,
    required this.contractId,
    required this.scheduleId,
    required this.scheduleRuleId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  FinancingConversionEvent copyWith({
    String? status,
    DateTime? updatedAt,
  }) {
    return FinancingConversionEvent(
      conversionId: conversionId,
      originChargeId: originChargeId,
      contractId: contractId,
      scheduleId: scheduleId,
      scheduleRuleId: scheduleRuleId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
