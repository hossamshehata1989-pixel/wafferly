import '../domain/financial_correction_record.dart';
import '../planning/financial_mutation.dart';

/// Persists an immutable financial correction and establishes the corrected
/// transaction materialized state.
final class CreateCorrectionMutation extends FinancialMutation {
  final FinancialCorrectionRecord record;

  const CreateCorrectionMutation({required this.record});
}
