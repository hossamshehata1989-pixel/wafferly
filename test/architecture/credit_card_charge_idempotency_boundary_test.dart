import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'credit-card charge application service requires a caller-owned key',
    () {
      final service = File(
        'lib/services/transaction_application_service.dart',
      ).readAsStringSync();
      final start = service.indexOf(
        'Future<OperationResult> addCreditCardCharge',
      );
      final end = service.indexOf(
        '// ================= Credit Card Payment',
        start,
      );

      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final method = service.substring(start, end);

      expect(method, contains('required String idempotencyKey'));
      expect(method, contains('idempotencyKey: idempotencyKey'));
      expect(method, isNot(contains('DateTime.now().microsecondsSinceEpoch')));
    },
  );

  test('both manual card-charge UI paths pass stable draft keys', () {
    final controller = File(
      'lib/controllers/transaction_entry_controller.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/screens/accounts/liabilities/credit_card_transaction_entry_screen.dart',
    ).readAsStringSync();

    expect(controller, contains('_ensureCreditCardChargeIdempotencyKey('));
    expect(controller, contains('idempotencyKey: idempotencyKey'));
    expect(screen, contains('_ensureChargeIdempotencyKey(amount: amount)'));
    expect(screen, contains('idempotencyKey: idempotencyKey'));
    expect(screen, contains('_invalidateChargeIdempotencyKey'));
    expect(
      screen,
      contains('_amountController.addListener(_handleChargeTextChanged)'),
    );
    expect(
      screen,
      contains('_merchantController.addListener(_handleChargeTextChanged)'),
    );
    expect(
      screen,
      contains('_noteController.addListener(_handleChargeTextChanged)'),
    );
    expect(
      screen,
      contains('if (signature == _observedChargeTextSignature) return;'),
    );
    expect(
      screen,
      isNot(contains('addListener(_invalidateChargeIdempotencyKey)')),
    );
  });

  test('installment workflow charge and down-payment keys remain explicit', () {
    final controller = File(
      'lib/controllers/transaction_entry_controller.dart',
    ).readAsStringSync();

    expect(
      controller,
      contains(r"'installment:$workflowId:credit-card-charge'"),
    );
    expect(controller, contains(r"'installment:$workflowId:down-payment'"));
  });
}
