import '../domain/financial_correction_record.dart';

/// Persistence port for immutable financial corrections.
abstract interface class CorrectionPort {
  Future<void> save(FinancialCorrectionRecord record);
  Future<FinancialCorrectionRecord?> findById(String correctionId);
  Future<void> delete(String correctionId);
}
