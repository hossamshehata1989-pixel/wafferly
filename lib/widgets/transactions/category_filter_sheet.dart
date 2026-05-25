import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/category_config.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/category_icons.dart';

class CategoryFilterSheet extends StatefulWidget {
  final List<CategoryConfig> categories;
  final List<String> selectedIds;

  const CategoryFilterSheet({
    super.key,
    required this.categories,
    required this.selectedIds,
  });

  @override
  State<CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<CategoryFilterSheet> {
  late Set<String> selected;

  final Set<String> expanded = {};

  @override
  void initState() {
    super.initState();

    selected = widget.selectedIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return FractionallySizedBox(
      heightFactor: .8,

      child: SafeArea(
        top: false,

        child: Container(
          padding: const EdgeInsets.all(11),

          decoration: const BoxDecoration(
            color: Color(0xFF101726),

            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),

          child: Column(
            children: [
              Text(
                t.categories,

                style: const TextStyle(
                  color: Colors.white,

                  fontSize: 22,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        selected.clear();
                      });
                    },

                    icon: const Icon(Icons.clear_all, size: 18),

                    label: const Text("Clear"),
                  ),

                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        selected.clear();

                        for (final category in widget.categories) {
                          selected.add(category.id);

                          if (category.subCategories != null) {
                            for (final sub in category.subCategories!) {
                              selected.add(sub.id);
                            }
                          }
                        }
                      });
                    },

                    icon: const Icon(Icons.done_all, size: 18),

                    label: const Text("Select All"),
                  ),

                  const Spacer(),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, selected.toList());
                    },

                    child: Text("Apply (${selected.length})"),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Divider(color: Colors.white24),

              Expanded(
                child: ListView.builder(
                  itemCount: widget.categories.length,

                  itemBuilder: (_, index) {
                    final category = widget.categories[index];

                    return _buildCategory(category, t);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(CategoryConfig category, AppLocalizations t) {
    final isExpanded = expanded.contains(category.id);

    final checked = selected.contains(category.id);

    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),

      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

            child: Row(
              textDirection: Directionality.of(context),
              children: [
                if (!isArabic)
                  Checkbox(
                    value: checked,

                    activeColor: Colors.pink,

                    onChanged: (_) {
                      _toggleCategory(category, checked);
                    },
                  ),

                CircleAvatar(
                  radius: 18,

                  backgroundColor: Colors.white10,

                  child: Padding(
                    padding: const EdgeInsets.all(5),

                    child: SvgPicture.asset(
                      getCategoryIcon(category.id),

                      width: 18,
                      height: 18,

                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.category,
                          size: 18,
                          color: Colors.white70,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    category.resolveTitle(t),

                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                if (category.subCategories != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          expanded.remove(category.id);
                        } else {
                          expanded.add(category.id);
                        }
                      });
                    },

                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,

                      color: Colors.white,
                    ),
                  ),

                if (isArabic)
                  Checkbox(
                    value: checked,

                    activeColor: Colors.pink,

                    onChanged: (_) {
                      _toggleCategory(category, checked);
                    },
                  ),
              ],
            ),
          ),

          if (isExpanded && category.subCategories != null)
            Padding(
              padding: const EdgeInsets.only(left: 45),

              child: Column(
                children: category.subCategories!.map((sub) {
                  final checked = selected.contains(sub.id);

                  return CheckboxListTile(
                    dense: true,

                    value: checked,

                    activeColor: Colors.pink,

                    secondary: CircleAvatar(
                      radius: 14,

                      backgroundColor: Colors.white10,

                      child: Padding(
                        padding: const EdgeInsets.all(4),

                        child: SvgPicture.asset(
                          getCategoryIcon(sub.id),

                          width: 14,
                          height: 14,

                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.category,
                              size: 14,
                              color: Colors.white70,
                            );
                          },
                        ),
                      ),
                    ),

                    title: Text(
                      sub.title(t),

                      style: const TextStyle(color: Colors.white),
                    ),

                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selected.add(sub.id);
                        } else {
                          selected.remove(sub.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleCategory(CategoryConfig category, bool checked) {
    setState(() {
      if (checked) {
        selected.remove(category.id);

        if (category.subCategories != null) {
          for (final sub in category.subCategories!) {
            selected.remove(sub.id);
          }
        }
      } else {
        selected.add(category.id);

        if (category.subCategories != null) {
          for (final sub in category.subCategories!) {
            selected.add(sub.id);
          }
        }
      }
    });
  }
}
