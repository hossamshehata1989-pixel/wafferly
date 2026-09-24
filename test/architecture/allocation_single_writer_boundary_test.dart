// test/architecture/allocation_single_writer_boundary_test.dart
//
// Guard test — Allocation Single Writer (Planning Engine).
//
// نفس منطق single_writer_boundary_test.dart بالظبط، لكن على
// AllocationRepository بدل TransactionService: أي ملف خارج الـ Planning
// Engine والـ Financial Engine (وأماكن الـ seam الموثّقة) لازم ميكتبش
// Allocation مباشرة (create/update/delete)، ولازم يعدي من PlanningEngine
// أو FinancialOperationEngine. القراءة (findBySource/findById/findActive)
// مش ممنوعة — القاعدة بتخص الكتابة بس.
//
// دليل: فحصت الكود وقت كتابة الاختبار ده ومفيش أي استخدام مباشر حاليًا
// خارج الأماكن المسموحة — يعني ده تأمين وقائي (Layer 2 defense)، مش
// إصلاح لمشكلة موجودة فعلاً زي حالة Transaction. الهدف إن أي feature
// جديدة تحاول تكتب Allocation مباشرة (بدل ما تعدي من الـ Engine) تتمسك
// فورًا قبل ما تتحول لـ bypass حقيقي.
//
// طريقة الفحص: أي سطر فيه ذكر لـ "llocationRepository" (بيمسك
// AllocationRepository / allocationRepository / _allocationRepository /
// sharedAllocationRepository بغض النظر عن اسم المتغيّر بالظبط) مع
// .create( أو .update( أو .delete( في نفس السطر — بعد ما نتجاهل أي حاجة
// بعد // في نفس السطر عشان نقلل false positives من التعليقات.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const List<String> _forbiddenSuffixes = ['.create(', '.update(', '.delete('];

/// الملفات/المجلدات المسموح لها تكتب Allocation مباشرة، مع سبب موثّق
/// لكل استثناء — السبب نفسه جزء من الـ architectural contract.
const Map<String, String> _whitelist = {
  'lib/core/planning':
      'الـ Planning Engine نفسه — صاحب الملكية الوحيد لـ Allocation. أي '
          'كتابة هنا هي التعريف الرسمي، مش تكرار له.',
  'lib/financial_engine':
      'الـ Financial Engine بيستدعي عمليات الـ Planning Engine كـ '
          'orchestrator (زي إنشاء/تحرير Allocation كجزء من عملية مالية '
          'أكبر)، مش بيكتب على الـ repository مباشرة من غير سياق engine.',
  'lib/infrastructure/adapters/allocation_adapter.dart':
      'الـ seam الموثّق بين FinancialOperationEngine (عبر AllocationPort) '
          'والـ Planning Engine — بينفّذ rollback عن طريق '
          'allocationRepository.update() كجزء من عقد الـ Financial '
          'Transaction Context (Compensation-based UnitOfWork)، مش bypass '
          'عشوائي على الـ repository.',
  'lib/infrastructure/memory/memory_allocation_repository.dart':
      'تنفيذ infrastructure-layer بديل (in-memory) لنفس عقد '
          'AllocationRepository — ده تنفيذ الـ contract نفسه (زي '
          'transaction_service.dart بالنسبة للـ Transaction)، مش استهلاك '
          'له من خارج الطبقة.',
};

void main() {
  test(
    'no file outside the Planning/Financial engines writes allocations directly',
    () {
      final libDir = Directory('lib');
      expect(
        libDir.existsSync(),
        isTrue,
        reason:
            'لازم تشغل الاختبار ده من جذر مشروع Flutter (المجلد اللي فيه lib/).',
      );

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String, List<String>>{};

      for (final file in dartFiles) {
        // مطابقة بالظبط لمسار project-relative منظم، أو بادئة مجلد
        // كاملة (مش endsWith) — عشان منسمحش بملف تاني اتفق إن مساره
        // بينتهي أو بيحتوي نفس النص بالصدفة.
        final relativePath = file.path
            .replaceAll('\\', '/')
            .replaceFirst(RegExp(r'^\./'), '');

        final isWhitelisted = _whitelist.keys.any(
          (allowed) =>
              relativePath == allowed || relativePath.startsWith('$allowed/'),
        );
        if (isWhitelisted) continue;

        final lines = file.readAsLinesSync();

        for (var i = 0; i < lines.length; i++) {
          final commentIndex = lines[i].indexOf('//');
          final line = commentIndex == -1
              ? lines[i]
              : lines[i].substring(0, commentIndex);

          if (!line.contains('llocationRepository')) continue;

          for (final suffix in _forbiddenSuffixes) {
            if (line.contains(suffix)) {
              violations.putIfAbsent(relativePath, () => []).add(
                    '  L${i + 1}: استخدام `$suffix` على AllocationRepository '
                    'مباشرة — لازم يعدي من PlanningEngine/'
                    'FinancialOperationEngine.',
                  );
            }
          }
        }
      }

      if (violations.isNotEmpty) {
        final buffer = StringBuffer()
          ..writeln()
          ..writeln(
            '🚫 لقيت ${violations.length} ملف بيكتب Allocation مباشرة:',
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
