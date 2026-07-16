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
          title: 'Discard Changes?',
          icon: Icons.warning_amber_rounded,
          onClose: () => Navigator.pop(context),
        ),

        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'You have an unfinished transaction.\n'
            'If you discard now, all entered data will be lost.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.45),
          ),
        ),

        const SizedBox(height: 28),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onContinueEditing?.call();
                  },
                  child: const Text('Continue Editing'),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 234, 107, 98),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onDiscard();
                  },
                  child: const Text('Discard'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
