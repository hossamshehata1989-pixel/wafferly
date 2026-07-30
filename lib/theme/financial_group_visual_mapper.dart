import 'financial_entity_visual.dart';
import 'financial_group_visual.dart';

extension FinancialGroupVisualMapper on FinancialGroupVisual {
  FinancialEntityVisual toEntityVisual() {
    return FinancialEntityVisual(
      backgroundSvg: background,
      surfaceAccent: color,
    );
  }
}
