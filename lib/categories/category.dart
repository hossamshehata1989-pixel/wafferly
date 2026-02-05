class Category {
  final int id;
  final String titleKey;
  final String icon;
  final List<SubCategory> subCategories;

  Category({
    required this.id,
    required this.titleKey,
    required this.icon,
    required this.subCategories,
  });
}

class SubCategory {
  final String titleKey;
  final String icon;

  SubCategory({
    required this.titleKey,
    required this.icon,
  });
}
