// ==========================================
// 📊 ANALYSIS CALCULATOR (FINAL)
// ==========================================

import '../../../models/expense.dart';

class AnalysisResult {
  final double total;
  final double normal;
  final double exceptional;

  final Map<String, double> normalCategories;
  final Map<String, double> totalCategories;

  AnalysisResult({
    required this.total,
    required this.normal,
    required this.exceptional,
    required this.normalCategories,
    required this.totalCategories,
  });
}

AnalysisResult calculateAnalysis(List<Expense> expenses) {
  double total = 0;
  double normal = 0;
  double exceptional = 0;

  Map<String, double> normalMap = {};
  Map<String, double> totalMap = {};

  for (var e in expenses) {
    total += e.amount;

    /// TOTAL MAP
    totalMap[e.category] =
        (totalMap[e.category] ?? 0) + e.amount;

    if (e.isExceptional) {
      exceptional += e.amount;
    } else {
      normal += e.amount;

      normalMap[e.category] =
          (normalMap[e.category] ?? 0) + e.amount;
    }
  }

  return AnalysisResult(
    total: total,
    normal: normal,
    exceptional: exceptional,
    normalCategories: normalMap,
    totalCategories: totalMap,
  );
}

////////////////////////////////////////////////////////
/// 🔥 TOP 4 + OTHER
////////////////////////////////////////////////////////

List<MapEntry<String, double>> getTopCategories(
  Map<String, double> data,
) {
  final sorted = data.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (sorted.length <= 4) return sorted;

  final top4 = sorted.take(4).toList();
  final others = sorted.skip(4);

  final otherSum =
      others.fold(0.0, (sum, e) => sum + e.value);

  top4.add(MapEntry("Other", otherSum));

  return top4;
}