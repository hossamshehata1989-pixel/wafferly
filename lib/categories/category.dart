import '../l10n/app_localizations.dart';

class Category {
  final String id;
  final String Function(AppLocalizations) title;
  final List<SubCategory> subCategories;

  const Category({
    required this.id,
    required this.title,
    required this.subCategories,
  });
}

class SubCategory {
  final String id;
  final String Function(AppLocalizations) title;

  const SubCategory({
    required this.id,
    required this.title,
  });
}