import '../../../models/expense.dart';

class AnalysisResult {
  final double total;
  final double normal;
  final double exceptional;

  final Map<String, double> totalCategories;
  final Map<String, double> normalCategories;

  AnalysisResult({
    required this.total,
    required this.normal,
    required this.exceptional,
    required this.totalCategories,
    required this.normalCategories,
  });
}

AnalysisResult calculateAnalysis(List<Expense> expenses) {

  double total = 0;
  double normal = 0;
  double exceptional = 0;

  final totalMap = <String, double>{};
  final normalMap = <String, double>{};

  for (final e in expenses) {

    total += e.amount;

    totalMap[e.mainCategory] =
        (totalMap[e.mainCategory] ?? 0) + e.amount;

    if (e.isExceptional) {
      exceptional += e.amount;
    } else {
      normal += e.amount;

      normalMap[e.mainCategory] =
          (normalMap[e.mainCategory] ?? 0) + e.amount;
    }
  }

  return AnalysisResult(
    total: total,
    normal: normal,
    exceptional: exceptional,
    totalCategories: totalMap,
    normalCategories: normalMap,
  );
}

/// TOP 4 + OTHER
List<MapEntry<String, double>> getTopCategories(
    Map<String, double> data) {

  final sorted = data.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (sorted.length <= 4) return sorted;

  final top4 = sorted.take(4).toList();

  final otherSum = sorted
      .skip(4)
      .fold(0.0, (sum, e) => sum + e.value);

  top4.add(MapEntry("Other", otherSum));

  return top4;
}