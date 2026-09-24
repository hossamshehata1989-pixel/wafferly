import '../domain/financial_correction_record.dart';
import '../ports/correction_port.dart';

final class MemoryCorrectionPort implements CorrectionPort {
  final Map<String, FinancialCorrectionRecord> records = {};

  @override
  Future<void> save(FinancialCorrectionRecord record) async {
    records[record.correctionId] = record;
  }

  @override
  Future<FinancialCorrectionRecord?> findById(String correctionId) async {
    return records[correctionId];
  }

  @override
  Future<void> delete(String correctionId) async {
    records.remove(correctionId);
  }
}
