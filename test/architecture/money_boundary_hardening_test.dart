import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planning balance boundary is Money-native', () {
    final files = <String>[
      'lib/core/planning/services/available_balance_projection_service.dart',
      'lib/core/planning/engine/guards/cannot_reserve_more_than_available_guard.dart',
      'lib/core/planning/bootstrap/planning_engine_bootstrap.dart',
    ];

    final violations = <String>[];
    final forbidden = RegExp(
      r'\bdouble\s+Function\s*\(String\s+accountId\)|\brequired\s+double\s+balance\b',
    );

    for (final path in files) {
      final file = File(path);
      if (!file.existsSync()) {
        violations.add('$path (missing)');
        continue;
      }

      for (final line in file.readAsLinesSync()) {
        if (forbidden.hasMatch(line)) {
          violations.add('$path: $line');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Planning balance APIs must remain Money-native.',
    );
  });

  test('TransactionLedgerBuilder accepts Money and owns the projection bridge', () {
    final path = 'lib/services/transaction_ledger_builder.dart';
    final source = File(path).readAsStringSync();

    expect(
      RegExp(r'required\s+Money\s+amount').hasMatch(source),
      isTrue,
      reason: 'Ledger builder must receive Money from financial callers.',
    );

    // LedgerEntry remains a legacy double-backed projection model. The builder
    // owns this single, explicit compatibility bridge at the constructor
    // boundary. Money must not be converted earlier in the financial API.
    expect(
      RegExp(r'_createEntry\([\s\S]*?amount: amount.toDouble\(\)').hasMatch(source),
      isTrue,
      reason: 'Ledger builder must own the single Money -> double projection bridge.',
    );

    // The invalidation/correction helper itself must remain Money-native.
    // It passes Money into the builder rather than converting it prematurely.
    expect(
      source.contains('amount: amount.toDouble(),\n      date: date,\n    );\n\n    return original;'),
      isFalse,
      reason: 'Correction/invalidation planning must not convert Money before the projection boundary.',
    );

    expect(
      RegExp(r'required\s+double\s+amount').hasMatch(source),
      isFalse,
      reason: 'Ledger builder must not expose a double monetary API.',
    );
  });
}
