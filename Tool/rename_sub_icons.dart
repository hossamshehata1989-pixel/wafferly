import 'dart:io';
import 'package:wafferly/config/category_config.dart';

void main() {
  const dirPath = 'assets/icons/subcategories';
  final dir = Directory(dirPath);

  if (!dir.existsSync()) {
    print('❌ Subcategories folder not found.');
    return;
  }

  final files = dir.listSync().whereType<File>().toList();

  print('\n========== RENAME SUB ICONS ==========\n');

  for (final main in [...expenseCategories, ...incomeCategories]) {
    for (final sub in main.subCategories ?? const []) {
      final id = sub.id;

      final correctName = 'sub_$id.svg';
      final correctPath = '${dir.path}/$correctName';

      if (File(correctPath).existsSync()) {
        continue;
      }

      final match = files.firstWhere(
        (f) =>
            f.path.toLowerCase().contains(id.toLowerCase()) &&
            f.path.endsWith('.svg'),
        orElse: () => File(''),
      );

      if (match.path.isNotEmpty) {
        match.renameSync(correctPath);
        print(
          '✅ Renamed: '
          '${match.path.split(Platform.pathSeparator).last} → $correctName',
        );
      } else {
        print('⚠️ No match found for id: $id');
      }
    }
  }

  print('\n======================================\n');
}