import '../l10n/app_localizations.dart';

// إضافة اسم مستعار (alias) لتوضيح المعنى
typedef Category = MainCategory;

class MainCategory {
  final String id;
  final String Function(AppLocalizations) title;
  final List<SubCategory> subCategories;

  const MainCategory({
    required this.id,
    required this.title,
    required this.subCategories,
  });
}

class SubCategory {
  final String id;
  final String Function(AppLocalizations) title;

  const SubCategory({required this.id, required this.title});
}
