// test/architecture/money_boundary_ratchet_test.dart
//
// Ratchet test — Money vs double Boundary.
//
// القاعدة الموثّقة عندك: Money/Decimal لازم يُستخدم جوه الـ domain، و
// double مسموح بس عند persistence/external-compatibility boundary
// "مُثبتة بالدليل" — مش blanket allowance تلقائي لأي ملف.
//
// الفرق عن باقي الاختبارات في المجلد ده: هنا مش استثناءين واضحين
// زي حالة الـ Transaction Single Writer، هنا انتشار حقيقي — 12 ملف
// تحت lib/financial_engine و lib/core/planning بيستخدموا `double amount`
// فعلاً دلوقتي (Intents، Mutations، Operations). كل ملف من الـ 12 دول
// محتاج منك قرار: مُثبت بالدليل فعلاً كـ boundary، ولا لسه واقف من
// غير تبرير حقيقي؟ القرار ده مش شغلي، وميتاخدش تلقائي من مجرد إن
// الكود موجود بالشكل ده حاليًا.
//
// فبدل ما الاختبار يفشل دلوقتي على حاجة موجودة أصلاً (وده هيضطرك تعمل
// whitelist لـ 12 ملف بسبب عام "لسه مش متبرر" — وده مش تبرير حقيقي)،
// الاختبار شغال كـ Ratchet:
//   - بيجمّد قائمة الملفات المعروفة (Technical Debt موثّق، مش موافقة).
//   - بيفشل بس لو (أ) ظهر ملف جديد بره القائمة بيستخدم نفس النمط —
//     يعني feature جديدة كررت نفس المشكلة بدل ما تستخدم Money، أو
//     (ب) — القائمة بحد ذاتها منظور استمرارها كتنبيه، مش فشل صريح.
//   - لو ملف اتصلح (بقى Money) الاختبار مش بيفشل، بيطبع رسالة تحسّن
//     إيجابية وبيطلب منك تحدّث _knownDoubleAmountDebt يدويًا — عشان
//     التحسّن يتقفل كـ baseline جديد، مش يفضل قابل للتراجع بصمت.
//
// يعني نجاح الاختبار مش معناه "المشكلة اتحلت" — معناه "مفيش تدهور
// جديد". أي تحسّن حقيقي (تقليل العدد) لازم يترافق مع تحديث يدوي
// للقائمة تحت، وإلا الـ ratchet مش هيعكس الواقع.
//
// دقة الفحص: الـ pattern هنا بيستخدم \b (word boundary) صراحة عشان
// يمنع false match لو "double"/"amount" جت جوه اسم أطول بالصدفة،
// وبيتجاهل أي حاجة بعد // في نفس السطر عشان تعليق زي
// "// TODO: remove double amount" ميتسجلش كـ debt غلط.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Technical debt معروف وقت كتابة الاختبار ده — مش موافقة عليه، مجرد
/// تجميد للوضع الحالي عشان مايكبرش من غير ما حد ياخد قرار واعي.
/// كل ملف هنا لازم في النهاية يتراجع ويتقرر مصيره: هجرة لـ Money، أو
/// توثيق رسمي كـ boundary مُثبت بالدليل (وينتقل لـ _provenBoundary).
const Set<String> _knownDoubleAmountDebt = {
  'lib/financial_engine/commands/expense/expense_intent.dart',
  'lib/financial_engine/commands/income/income_intent.dart',
  'lib/financial_engine/commands/opening_balance/opening_balance_intent.dart',
  'lib/financial_engine/commands/transfer/transfer_intent.dart',
  'lib/financial_engine/interpretation/normalized_intent.dart',
  'lib/financial_engine/mutations/goal_activity_mutation.dart',
  'lib/financial_engine/mutations/release_allocation_mutation.dart',
  'lib/financial_engine/operations/commitment_payment_operation.dart',
  'lib/financial_engine/operations/create_allocation_mutation.dart',
  'lib/financial_engine/operations/create_goal_allocation_operation.dart',
  'lib/financial_engine/operations/goal_saving_transfer_operation.dart',
  'lib/financial_engine/operations/goal_transfer_operation.dart',
};

/// Boundaries مُثبتة بالدليل رسميًا (persistence layer) — مش دِين،
/// دي نقطة التحويل الشرعية بين double (Hive) و Money (domain)، ومستبعدة
/// من الفحص بالكامل بدل ما تتعد كـ debt.
const Map<String, String> _provenBoundary = {
  'lib/core/planning/infrastructure/persistence/hive_allocation_record.dart':
      'نقطة تحويل Hive boundary موثّقة — مطابقة لقاعدة "double مسموح عند '
          'persistence boundary مُثبتة بالدليل".',
};

/// نمط دقيق (word-boundary) بدل alternation بسيط: بيمسك
/// `double amount` / `final double amount` / `required double amount`
/// و `amount: double` — من غير ما يتأثر بأسماء أطول بالصدفة تحتوي
/// نفس الكلمات.
final RegExp _doubleAmountPattern = RegExp(
  r'\b(?:final\s+|required\s+)?double\s+amount\b|\bamount\s*:\s*double\b',
);

void main() {
  test(
    'domain layer does not grow new double-typed amount fields beyond documented debt',
    () {
      const scannedRoots = ['lib/financial_engine', 'lib/core/planning'];
      final currentFiles = <String>{};

      for (final root in scannedRoots) {
        final dir = Directory(root);
        if (!dir.existsSync()) continue;

        final dartFiles = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in dartFiles) {
          final relativePath = file.path
              .replaceAll('\\', '/')
              .replaceFirst(RegExp(r'^\./'), '');

          if (_provenBoundary.containsKey(relativePath)) continue;

          final lines = file.readAsLinesSync();
          for (final rawLine in lines) {
            final line = _withoutLineComment(rawLine);
            if (_doubleAmountPattern.hasMatch(line)) {
              currentFiles.add(relativePath);
              break;
            }
          }
        }
      }

      final newDebt = currentFiles.difference(_knownDoubleAmountDebt);
      final resolvedDebt = _knownDoubleAmountDebt.difference(currentFiles);

      if (resolvedDebt.isNotEmpty) {
        // مش فشل — تنبيه إيجابي: ملفات اتهاجرت لـ Money. حدّث القائمة
        // فوق وشيلها من _knownDoubleAmountDebt عشان الـ ratchet يتقفل
        // على التحسّن الجديد كـ baseline، بدل ما يفضل الفرق ده مفتوح.
        // ignore: avoid_print
        print(
          '✅ تحسّن: ${resolvedDebt.length} ملف مبقاش فيه double amount '
          'بعد كدا — حدّث _knownDoubleAmountDebt: $resolvedDebt',
        );
      }

      if (newDebt.isNotEmpty) {
        final buffer = StringBuffer()
          ..writeln()
          ..writeln(
            '🚫 لقيت ${newDebt.length} ملف جديد بيستخدم double amount في '
            'الـ domain layer، مش موجود في _knownDoubleAmountDebt:',
          )
          ..writeln();

        for (final path in newDebt) {
          buffer.writeln('📄 $path');
        }

        buffer
          ..writeln()
          ..writeln(
            'لو ده feature جديدة: استخدم Money بدل double. لو ده boundary '
            'مُثبت بالدليل فعلًا: وثّقه في _provenBoundary مع السبب، مش في '
            '_knownDoubleAmountDebt (اللي معناها "دِين لسه ملهوش قرار").',
          );

        fail(buffer.toString());
      }
    },
  );
}

String _withoutLineComment(String line) {
  final commentIndex = line.indexOf('//');
  return commentIndex == -1 ? line : line.substring(0, commentIndex);
}
