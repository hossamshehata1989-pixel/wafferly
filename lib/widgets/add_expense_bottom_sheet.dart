import 'package:flutter/material.dart';
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
  DateTime selectedDate = DateTime.now();

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

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "EGP $amount",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.directions_car, size: 32),
                        const SizedBox(height: 6),
                        Text(widget.categoryName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: GridView.count(
                    controller: widget.scrollController,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      ...["7","8","9","4","5","6","1","2","3"]
                          .map((n) => keypadButton(n)),
                      keypadButton("C", onTap: clear),
                      keypadButton("0"),
                      keypadButton("="),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      actionButton(Icons.calendar_today, t.date, () {}),
                      const SizedBox(height: 12),
                      actionButton(Icons.note_alt, t.notes, () {}),
                      const SizedBox(height: 12),
                      actionButton(Icons.save, t.save, () {},
                          color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget keypadButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => addNumber(text),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget actionButton(
      IconData icon, String text, VoidCallback onTap,
      {Color? color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: color ?? Colors.grey.shade300,
          foregroundColor:
              color != null ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
      ),
    );
  }
}
