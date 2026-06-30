import '../resolution/resolution.dart';

abstract class FinancialOperation {
  final Resolution? resolution;

  const FinancialOperation({this.resolution});

  bool get hasResolution => resolution != null;

  FinancialOperation resolve(Resolution resolution);
}
