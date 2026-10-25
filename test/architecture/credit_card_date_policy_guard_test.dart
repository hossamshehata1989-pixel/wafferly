import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Repository-wide guard against reintroducing inline card-cycle math or
/// creating installment schedules that start on the current date by default.
/// This deliberately scans every production Dart file, including newly added
/// files, rather than checking only the currently known screen files.
void main() {
  final libRoot = Directory('lib');

  test('credit-card transaction timeline UI delegates dates to policy', () {
    final details = File(
      'lib/screens/accounts/liabilities/credit_card_account_details_screen.dart',
    ).readAsStringSync();
    final entry = File(
      'lib/screens/accounts/liabilities/credit_card_transaction_entry_screen.dart',
    ).readAsStringSync();
    final conversion = File(
      'lib/screens/accounts/liabilities/credit_card_installment_conversion_screen.dart',
    ).readAsStringSync();
    final financingService = File(
      'lib/application/credit_card/credit_card_financing_application_service.dart',
    ).readAsStringSync();

    expect(details, contains('CreditCardTransactionTimingPolicy.statementDateForPurchase'));
    expect(
      details,
      matches(RegExp(
        r'CreditCardTransactionTimingPolicy\s*\.firstOutstandingInstallmentDueDateForCharge',
      )),
    );
    expect(entry, contains('CreditCardFirstDueDatePolicy.defaultFirstDueDate'));
    expect(conversion, contains('CreditCardFirstDueDatePolicy.defaultFirstDueDate'));
    expect(financingService, contains('CreditCardFirstDueDatePolicy.installmentDueDate'));
  });

  test('no production file recomputes statement month from transaction month', () {
    final forbidden = <RegExp>[
      // The old bug: DateTime(tx.date.year, tx.date.month + ... statementDay).
      RegExp(
        r'DateTime\s*\(\s*(?:tx|charge|purchase)\.date\.year\s*,\s*(?:tx|charge|purchase)\.date\.month[\s\S]{0,180}?(?:statementDay|paymentDueDay)',
        caseSensitive: false,
      ),
      // Also catch equivalent direct month increments that don't name the
      // settings variable in the same constructor.
      RegExp(
        r'(?:statementMonth|nextStatementMonth)\s*=\s*DateTime\s*\(\s*(?:tx|charge|purchase)\.date\.year\s*,\s*(?:tx|charge|purchase)\.date\.month\s*\+',
        caseSensitive: false,
      ),
      // Schedule generation must use the shared anchor/clamping policy too.
      RegExp(
        r'DateTime\s*\(\s*firstDueDate\.year\s*,\s*firstDueDate\.month\s*\+\s*(?:index|installmentIndex)',
        caseSensitive: false,
      ),
    ];

    final offenders = _dartFiles(libRoot).where((file) {
      // The policy file is the one approved owner of anchor-preserving date
      // arithmetic; all other files must delegate to it.
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (normalizedPath.endsWith(
        'lib/application/credit_card/credit_card_first_due_date_policy.dart',
      )) {
        return false;
      }
      final source = file.readAsStringSync();
      return forbidden.any((pattern) => pattern.hasMatch(source));
    }).map((file) => file.path).toList();

    expect(
      offenders,
      isEmpty,
      reason: 'Use CreditCardCycleResolver / CreditCardTransactionTimingPolicy '
          'instead of hand-written month arithmetic. Offenders: $offenders',
    );
  });

  test('no production file defaults a first installment date to DateTime.now', () {
    final forbidden = <RegExp>[
      RegExp(
        r'\b(?:_firstPaymentDate|_firstDueDate|firstPaymentDate|firstDueDate)\s*=\s*DateTime\.now\s*\(',
        caseSensitive: false,
      ),
      RegExp(
        r'firstDueDate\s*:\s*DateTime\.now\s*\(',
        caseSensitive: false,
      ),
      // Require one shared policy for schedule expansion; a local helper would
      // bypass the tested original-day anchor and month-end clamping contract.
      RegExp(
        r'\b_addMonths\s*\(\s*firstDueDate\s*,\s*(?:index|installmentIndex)',
        caseSensitive: false,
      ),
    ];

    final offenders = _dartFiles(libRoot).where((file) {
      final source = file.readAsStringSync();
      return forbidden.any((pattern) => pattern.hasMatch(source));
    }).map((file) => file.path).toList();

    expect(
      offenders,
      isEmpty,
      reason: 'Installment creation must use the shared first-due-date policy '
          'or an explicit user-selected date. Offenders: $offenders',
    );
  });
}

Iterable<File> _dartFiles(Directory root) sync* {
  if (!root.existsSync()) return;
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}
