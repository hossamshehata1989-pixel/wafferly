import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final libRoot = Directory('lib');

  List<File> dartFiles() => libRoot
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  test('legacy TransactionService is isolated from production callers', () {
    const allowedCompatibilityFile =
        'lib/services/transaction_service.dart';
    final violations = <String>[];

    for (final file in dartFiles()) {
      final normalized = file.path.replaceAll('\\', '/');
      if (normalized == allowedCompatibilityFile) continue;

      final source = file.readAsStringSync();

      if (source.contains("import 'transaction_service.dart'") ||
          source.contains("import '../services/transaction_service.dart'") ||
          source.contains("import '../../services/transaction_service.dart'") ||
          source.contains('TransactionService.instance')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Production callers must use TransactionQueryService; '
          'TransactionService is compatibility-only.',
    );
  });

  test('TransactionQueryService is the production transaction read API', () {
    final source =
        File('lib/services/transaction_query_service.dart').readAsStringSync();

    expect(source, contains('FinancialEffectiveTransactionQuery'));
    expect(source, contains('getEffectiveTransactions'));
    expect(source, contains('getEffectiveById'));

    // TransactionQueryService is read-only and must not mutate
    // the transaction persistence store.
    final persistenceMutationPattern = RegExp(
      r'\b(?:_box|box|transactionsBox)\s*\.\s*'
      r'(?:put|add|delete|clear)\s*\(',
      caseSensitive: false,
    );

    expect(
      source,
      isNot(matches(persistenceMutationPattern)),
      reason:
          'TransactionQueryService must not mutate the transaction store.',
    );
  });
}