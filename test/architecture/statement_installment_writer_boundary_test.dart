import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('statement/installment integration does not write financial truth', () {
    final files = <String>[
      'lib/financing/domain/credit_card_statement_installment_service.dart',
      'lib/financing/domain/statement_installment_contribution_repository.dart',
      'lib/financing/infrastructure/hive_statement_installment_contribution_repository.dart',
    ];

    final forbidden = <String>[
      'TransactionApplicationService',
      'FinancialOperationEngine',
      'Hive.box<Transaction>',
      'Hive.box<Account>',
      'transactions.put(',
      'transactions.delete(',
      'accounts.put(',
      'accounts.delete(',
      'ledger_entries',
      'financial_idempotency',
    ];

    for (final path in files) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing $path');
      final source = file.readAsStringSync();
      for (final token in forbidden) {
        expect(
          source,
          isNot(contains(token)),
          reason: '$path must not contain financial-truth writer $token',
        );
      }
    }
  });
}
