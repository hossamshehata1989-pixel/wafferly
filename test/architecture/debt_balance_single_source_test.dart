// test/architecture/debt_balance_single_source_test.dart
//
// Guard test — Debt Balance Single Source.
//
// القاعدة الموثّقة عندك: أي "Total Outstanding / Overdue / Due Soon"
// لازم يكون Derived Read Model/Projection من DebtQueryService، مش
// aggregation مستقل جوه أي شاشة presentation أو service تاني.
//
// النطاق مقصود يكون lib/screens + lib/services (مش lib/screens/manage
// بس) لأن القاعدة نفسها أوسع من مكان الـ bug الحالي: أي طبقة
// presentation أو service ممكن تكرر نفس الغلطة مستقبلًا، مش بس شاشات
// الـ manage. الاختبار بيحمي الـ architectural invariant نفسه، مش
// بس الموقع اللي ظهرت فيه أول مرة.
//
// دليل حقيقي من الكود (وقت كتابة الاختبار ده): debts_screen.dart بيعمل
//   final totalOutstanding = summaries.fold<double>(
//     0,
//     (sum, item) => sum + item.outstanding.toDouble(),
//   );
// يعني بياخد summaries من DebtQueryService.getDebtSummaries() (صح)،
// لكن بعدين بيجمّعها (fold) بنفسه في الـ UI layer بدل ما ياخد رقم
// إجمالي جاهز من الـ service. ده بالظبط النمط اللي الاختبار ده بيمنعه.
//
// طريقة الفحص: أي سطر فيه `.fold` وبعده بحد أقصى 4 أسطر فيها
// `outstanding` أو `overdue` (case-insensitive) — يعتبر aggregation
// مستقل لرقم دين إجمالي، خارج نطاق الملفات المسموح لها.
//
// ملاحظة صريحة زي اختبار الـ Transaction: فحص نصّي مش semantic —
// نافذة الـ 4 أسطر بتقلل false positives (زي fold تاني في نفس الملف
// لحاجة مالهاش علاقة بالدين، زي goalProgress أو budgetUsage) لكن مش
// ضمان كامل. وبيتجاهل أي حاجة بعد // في نفس السطر عشان تعليق ميتسجلش
// كـ violation غلط.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const int _lookaheadLines = 4;

/// الملفات المسموح لها تعمل aggregation لأرقام الدين لأنها هي نفسها
/// مصدر الحقيقة المفروض يُستدعى منه، أو نموذج بيانات بلا منطق تجميع.
const Map<String, String> _whitelist = {
  'lib/services/debt_query_service.dart':
      'المصدر الوحيد المفروض يُحسب منه أي Total Outstanding/Overdue/Due '
          'Soon — التجميع هنا هو التعريف الرسمي، مش تكرار له.',
  'lib/models/debt/debt_summary.dart':
      'نموذج بيانات (data model) بيحمل حقل outstanding لكل عنصر — مفيش '
          'فيه منطق تجميع، والوجود هنا للـ documentation بس.',
};

void main() {
  test(
    'no file outside DebtQueryService aggregates outstanding/overdue totals independently',
    () {
      final libDir = Directory('lib');
      expect(
        libDir.existsSync(),
        isTrue,
        reason:
            'لازم تشغل الاختبار ده من جذر مشروع Flutter (المجلد اللي فيه lib/).',
      );

      const scannedRoots = ['lib/screens', 'lib/services'];

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where(
            (f) => scannedRoots.any(
              (root) => f.path.replaceAll('\\', '/').startsWith(root),
            ),
          );

      final violations = <String, List<String>>{};

      for (final file in dartFiles) {
        final relativePath = file.path
            .replaceAll('\\', '/')
            .replaceFirst(RegExp(r'^\./'), '');

        if (_whitelist.containsKey(relativePath)) continue;

        final lines = file.readAsLinesSync();

        for (var i = 0; i < lines.length; i++) {
          final codeLine = _withoutLineComment(lines[i]);
          if (!codeLine.contains('.fold')) continue;

          final windowEnd = (i + 1 + _lookaheadLines).clamp(0, lines.length);
          final window = lines
              .sublist(i, windowEnd)
              .map(_withoutLineComment)
              .join('\n')
              .toLowerCase();

          if (window.contains('outstanding') || window.contains('overdue')) {
            violations.putIfAbsent(relativePath, () => []).add(
                  '  L${i + 1}: `.fold` مع outstanding/overdue خلال '
                  '$_lookaheadLines أسطر — ده تجميع مستقل لرقم دين، '
                  'المفروض ياخده جاهز من DebtQueryService.',
                );
          }
        }
      }

      if (violations.isNotEmpty) {
        final buffer = StringBuffer()
          ..writeln()
          ..writeln(
            '🚫 لقيت ${violations.length} ملف بيعمل aggregation مستقل لرقم دين:',
          )
          ..writeln();

        violations.forEach((path, issues) {
          buffer.writeln('📄 $path');
          for (final issue in issues) {
            buffer.writeln(issue);
          }
          buffer.writeln();
        });

        fail(buffer.toString());
      }
    },
  );
}

String _withoutLineComment(String line) {
  final commentIndex = line.indexOf('//');
  return commentIndex == -1 ? line : line.substring(0, commentIndex);
}
