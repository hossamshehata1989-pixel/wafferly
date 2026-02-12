class Category {
  final String id;
  final String titleKey;
  final List<SubCategory> subCategories;

  const Category({
    required this.id,
    required this.titleKey,
    required this.subCategories,
  });
}

class SubCategory {
  final String id;
  final String titleKey;

  const SubCategory({
    required this.id,
    required this.titleKey,
  });
}
