import 'package:flutter/material.dart';

import '../bottom_sheet/sheet_header.dart';

class DiscardEntrySheet extends StatelessWidget {
  final VoidCallback onDiscard;
  final VoidCallback? onContinueEditing;

  const DiscardEntrySheet({
    super.key,
    required this.onDiscard,
    this.onContinueEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader(
          title: 'Discard Changes ?',
          icon: Icons.warning_amber_rounded,
          onClose: () => Navigator.pop(context),
        ),

        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'You have an unfinished transaction.\n'
            'If you discard now, the current entered data will be lost.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.45),
          ),
        ),

        // ✅ مسافة إضافية بعد البطاقة
        const SizedBox(height: 32),

        // ✅ الأزرار المعدلة
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(
            children: [
              Flexible(
                flex: 6,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onContinueEditing?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    side: const BorderSide(color: Color(0xFF7D73FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Keep Editing',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 5,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFFEF6A5F),
                    foregroundColor: Colors.white, // ← ده لون النص والأيقونة
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onDiscard();
                  },
                  child: const Text(
                    'Discard',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
