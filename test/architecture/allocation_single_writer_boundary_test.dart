// Allocation Single Writer boundary.
//
// AllocationRepository mutations are owned exclusively by the Planning
// Engine. Consumers may read through the repository, but must not call
// create/update/delete outside lib/core/planning. Financial Engine seams
// must invoke PlanningEngine operations instead of compensating through
// direct repository writes.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const List<String> _forbiddenSuffixes = ['.create(', '.update(', '.delete('];

const Map<String, String> _whitelist = {
  'lib/core/planning':
      'The Planning Engine owns AllocationRepository mutations exclusively.',
};

void main() {
  test(
    'no file outside the Planning Engine writes allocations directly',
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
