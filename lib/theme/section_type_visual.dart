import '../models/enums/section_type.dart';
import 'financial_group_visual.dart';
import 'financial_group_visual_resolver.dart';

extension SectionTypeVisual on SectionType {
  FinancialGroupVisual get groupVisual {
    return FinancialGroupVisualResolver.resolve(this);
  }
}
