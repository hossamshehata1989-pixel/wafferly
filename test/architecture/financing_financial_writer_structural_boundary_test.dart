import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'financing and credit-card domains cannot mutate Account or Transaction boxes',
    () {
      const scannedRoots = <String>['lib/financing', 'lib/credit_card'];
      final violations = <String>[];
      final typedBoxDeclaration = RegExp(
        r'\bBox<(?:Transaction|Account)>\s+([A-Za-z_]\w*)',
      );
      final directHiveMutation = RegExp(
        r'Hive\.box<(?:Transaction|Account)>\([^)]*\)\s*\.\s*(put|add|delete|clear)\s*\(',
      );

      for (final root in scannedRoots) {
        final dir = Directory(root);
        if (!dir.existsSync()) continue;

        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));

        for (final file in files) {
          final normalized = file.path.replaceAll('\\', '/');
          final source = file.readAsStringSync();
          final withoutComments = source
              .split('\n')
              .map((line) => line.split('//').first)
              .join('\n');

          if (directHiveMutation.hasMatch(withoutComments)) {
            violations.add('$normalized: direct Hive Account/Transaction mutation');
          }

          final boxNames = typedBoxDeclaration
              .allMatches(withoutComments)
              .map((match) => match.group(1)!)
              .toSet();

          for (final name in boxNames) {
            final mutation = RegExp(
              '\\b${RegExp.escape(name)}\\s*\\.\\s*(put|add|delete|clear)\\s*\\(',
            );
            if (mutation.hasMatch(withoutComments)) {
              violations.add('$normalized: $name Account/Transaction mutation');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Financing and credit-card domains must not mutate financial truth. '
            'This boundary is structural: Box<Account>/Box<Transaction> declarations '
            'are detected by type, independent of variable name or injection style.',
      );
    },
  );
}
