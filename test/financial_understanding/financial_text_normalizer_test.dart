import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/financial_understanding/normalization/financial_text_normalizer.dart';

void main() {
  const normalizer = FinancialTextNormalizer();

  group('FinancialTextNormalizer', () {
    test('normalizes Arabic-Indic digits and Arabic decimal separator', () {
      expect(
        normalizer.normalize('تم خصم ١٢٣٫٥٠ ج.م'),
        'تم خصم 123.50 ج.م',
      );
    });

    test('normalizes Persian digits too', () {
      expect(normalizer.normalize('مبلغ ۱۲۳۴'), 'مبلغ 1234');
    });

    test('preserves explicit grouping separator as comma', () {
      expect(normalizer.normalize('المبلغ ١٬٢٥٠'), 'المبلغ 1,250');
    });

    test('removes Arabic marks and tatweel', () {
      expect(normalizer.normalize('إِيـداع'), 'إيداع');
    });

    test('normalizes whitespace including non-breaking spaces', () {
      expect(normalizer.normalize('  خصم\u00A0\n  ٥٠  '), 'خصم 50');
    });

    test('empty or whitespace input becomes empty', () {
      expect(normalizer.normalize('  \n\t '), isEmpty);
    });
  });
}
