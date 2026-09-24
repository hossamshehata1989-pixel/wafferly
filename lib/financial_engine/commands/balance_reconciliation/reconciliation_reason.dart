enum ReconciliationReason {
  cashCountDifference,
  bankStatementReconciliation,
  previouslyUnrecorded,
  dataMigrationCorrection,
  other,
}

extension ReconciliationReasonLabel on ReconciliationReason {
  String get value {
    switch (this) {
      case ReconciliationReason.cashCountDifference:
        return 'cashCountDifference';
      case ReconciliationReason.bankStatementReconciliation:
        return 'bankStatementReconciliation';
      case ReconciliationReason.previouslyUnrecorded:
        return 'previouslyUnrecorded';
      case ReconciliationReason.dataMigrationCorrection:
        return 'dataMigrationCorrection';
      case ReconciliationReason.other:
        return 'other';
    }
  }
}
