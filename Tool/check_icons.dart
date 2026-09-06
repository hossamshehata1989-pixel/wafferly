import 'dart:io';
import 'package:wafferly/config/category_config.dart';

void main() {
  final missing = <String>[];

  void checkId(String id) {
    final mainPath = 'assets/icons/categories/category_$id.svg';
    final subPath = 'assets/icons/subcategories/sub_$id.svg';

    final mainFile = File(mainPath);
    final subFile = File(subPath);

    if (!mainFile.existsSync() && !subFile.existsSync()) {
      missing.add(id);
    }
  }

  for (final main in [...expenseCategories, ...incomeCategories]) {
    checkId(main.id);

    for (final sub in main.subCategories ?? const []) {
  checkId(sub.id);
}
  }

  print('\n========== ICON CHECK REPORT ==========\n');

  if (missing.isEmpty) {
    print('✅ All icons exist. Perfect 👌');
  } else {
    print('❌ Missing icons (${missing.length}):\n');

    for (final id in missing) {
      print('category_$id.svg OR sub_$id.svg');
    }
  }

  print('\n=======================================\n');
}