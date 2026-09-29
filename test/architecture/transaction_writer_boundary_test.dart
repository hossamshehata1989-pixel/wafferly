import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final libRoot = Directory('lib');

  List<File> dartFiles() {
    return libRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
  }

  test('no production code exposes legacy generic transaction writers', () {
    const forbiddenPatterns = <String>[
      '.addTransaction(',
      '.updateTransaction(',
      '.deleteTransaction(',
      '.deleteAllTransactions(',
    ];

    final violations = <String>[];

    for (final file in dartFiles()) {
      final source = file.readAsStringSync();
      for (final pattern in forbiddenPatterns) {
        if (source.contains(pattern)) {
          violations.add('${file.path}: $pattern');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Legacy generic transaction writer APIs must not exist in lib/.',
    );
  });

  test('transaction persistence writes exist only in HiveTransactionPort', () {
    const allowedWriter = 'lib/financial_engine/adapters/hive_transaction_port.dart';
    final violations = <String>[];

    final directHiveMutation = RegExp(
      r'Hive\.box<Transaction>\([^)]*\)\s*\.\s*(put|add|delete|clear)\s*\(',
    );
    final typedBoxDeclaration = RegExp(
      r'\bBox<Transaction>\s+([A-Za-z_]\w*)',
    );

    for (final file in dartFiles()) {
      final normalized = file.path.replaceAll('\\', '/');
      if (normalized == allowedWriter) continue;

      final source = file.readAsStringSync();
      final withoutComments = source
          .split('\n')
          .map((line) => line.split('//').first)
          .join('\n');

      if (directHiveMutation.hasMatch(withoutComments)) {
        violations.add('$normalized: direct Hive Transaction box mutation');
      }

      final transactionBoxNames = typedBoxDeclaration
          .allMatches(withoutComments)
          .map((match) => match.group(1)!)
          .toSet();

      for (final name in transactionBoxNames) {
        if (RegExp(
          '\\b${RegExp.escape(name)}\\s*\\.\\s*(put|add|delete|clear)\\s*\\(',
        ).hasMatch(withoutComments)) {
          violations.add('$normalized: $name transaction-box mutation');
        }
      }

    }

    expect(
      violations,
      isEmpty,
      reason:
          'The transactions Hive box must only be mutated by HiveTransactionPort; '
          'the boundary is enforced structurally by Box<Transaction> type, not variable name.',
    );
  });

  test('TransactionService is query-only and has no generic writer methods', () {
    final source = File('lib/services/transaction_service.dart').readAsStringSync();

    expect(source, isNot(contains('Future<void> addTransaction(')));
    expect(source, isNot(contains('Future<void> updateTransaction(')));
    expect(source, isNot(contains('Future<void> deleteTransaction(')));
    expect(source, isNot(contains('Future<void> deleteAllTransactions(')));
  });

  test('TransactionApplicationService has no legacy mutation seam', () {
    final source =
        File('lib/services/transaction_application_service.dart').readAsStringSync();

    expect(source, isNot(contains('addTransaction(Transaction')));
    expect(source, isNot(contains('updateTransaction(Transaction')));
    expect(source, isNot(contains('deleteTransaction(String')));
    expect(source, isNot(contains('deleteAllTransactions()')));
    expect(source, isNot(contains('_legacyTransactionService.add')));
    expect(source, isNot(contains('_legacyTransactionService.update')));
    expect(source, isNot(contains('_legacyTransactionService.delete')));
  });
}
