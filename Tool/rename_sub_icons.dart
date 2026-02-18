import 'dart:io';
import '../lib/data/categories_data.dart';

void main() {
  final dir = Directory('assets/icons/subcategories');

  if (!dir.existsSync()) {
    print('❌ Subcategories folder not found.');
    return;
  }

  final files = dir.listSync().whereType<File>().toList();

  print('\n========== RENAME SUB ICONS ==========\n');

  for (final main in mainCategories) {
    for (final sub in main.subCategories) {
      final id = sub.id;

      // الاسم الصحيح المطلوب
      final correctName = 'sub_$id.svg';
      final correctPath = '${dir.path}/$correctName';

      // لو الملف موجود بالفعل بالاسم الصح → سيبه
      if (File(correctPath).existsSync()) {
        continue;
      }

      // دور على ملف يحتوي على الـ id في اسمه
      final match = files.firstWhere(
        (f) =>
            f.path.toLowerCase().contains(id.toLowerCase()) &&
            f.path.endsWith('.svg'),
        orElse: () => File(''),
      );

      if (match.path.isNotEmpty) {
        match.renameSync(correctPath);
        print('✅ Renamed: ${match.path.split('/').last} → $correctName');
      } else {
        print('⚠️ No match found for id: $id');
      }
    }
  }

  print('\n======================================\n');
}
