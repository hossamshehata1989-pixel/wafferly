import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

void showAddExpenseSheet(BuildContext context, String categoryName) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => AddExpenseBottomSheet(
        categoryName: categoryName,
        scrollController: controller,
      ),
    ),
  );
}

class AddExpenseBottomSheet extends StatefulWidget {
  final String categoryName;
  final ScrollController scrollController;

  const AddExpenseBottomSheet({
    super.key,
    required this.categoryName,
    required this.scrollController,
  });

  @override
  State<AddExpenseBottomSheet> createState() =>
      _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  String amount = "0";

  void addNumber(String n) {
    setState(() {
      if (amount == "0") {
        amount = n;
      } else {
        amount += n;
      }
    });
  }

  void clear() => setState(() => amount = "0");

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final formattedAmount = NumberFormat.currency(
      locale: locale,
      symbol: locale.startsWith('ar') ? 'ج.م' : 'EGP',
    ).format(double.tryParse(amount) ?? 0);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Text(
                        formattedAmount,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GridView.count(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  ...["7", "8", "9", "4", "5", "6", "1", "2", "3"]
                      .map((n) => keypadButton(n)),
                  keypadButton("C", onTap: clear),
                  keypadButton("0"),
                  const SizedBox(), // بدل "=" مؤقتًا
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget keypadButton(String text,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => addNumber(text),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
