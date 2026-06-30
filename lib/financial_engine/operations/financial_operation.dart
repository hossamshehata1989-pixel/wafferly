import '../resolution/resolution.dart';

abstract class FinancialOperation {
  const FinancialOperation();

  FinancialOperation resolve(Resolution resolution);
}
