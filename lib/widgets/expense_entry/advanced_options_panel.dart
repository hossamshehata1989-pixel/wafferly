// lib/widgets/expense_entry/advanced_options_panel.dart
import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../l10n/app_localizations.dart';

class AdvancedOptionsPanel extends StatefulWidget {
  final TransactionEntryController controller;

  const AdvancedOptionsPanel({super.key, required this.controller});

  @override
  State<AdvancedOptionsPanel> createState() => _AdvancedOptionsPanelState();
}

class _AdvancedOptionsPanelState extends State<AdvancedOptionsPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Icon(
              _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              color: Colors.white54,
            ),
            title: Text(
              t.advancedOptions,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: Icon(
              _expanded ? Icons.close : Icons.add,
              color: Colors.white54,
              size: 18,
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Note
                  _buildOptionTile(
                    icon: Icons.note,
                    label: t.note,
                    subtitle: widget.controller.note.isNotEmpty ? widget.controller.note : null,
                    onTap: () => _showNoteDialog(context, t),
                  ),
                  const SizedBox(height: 8),
                  // Future options (disabled for now)
                  _buildOptionTile(
                    icon: Icons.repeat,
                    label: t.recurringTransaction,
                    isDisabled: true,
                    onTap: () => _showComingSoon(context, t),
                  ),
                  const SizedBox(height: 8),
                  _buildOptionTile(
                    icon: Icons.attach_file,
                    label: t.attachPhoto,
                    isDisabled: true,
                    onTap: () => _showComingSoon(context, t),
                  ),
                  const SizedBox(height: 8),
                  _buildOptionTile(
                    icon: Icons.scanner,
                    label: t.scanReceipt,
                    isDisabled: true,
                    onTap: () => _showComingSoon(context, t),
                  ),
                  const SizedBox(height: 8),
                  _buildOptionTile(
                    icon: Icons.location_on,
                    label: t.location,
                    isDisabled: true,
                    onTap: () => _showComingSoon(context, t),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    String? subtitle,
    bool isDisabled = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDisabled ? Colors.white38 : Colors.white54, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDisabled ? Colors.white38 : Colors.white70,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12))
          : null,
      trailing: Icon(
        isDisabled ? Icons.lock_outline : Icons.chevron_right,
        color: isDisabled ? Colors.white38 : Colors.blue,
        size: 20,
      ),
      onTap: isDisabled ? null : onTap,
    );
  }

  void _showNoteDialog(BuildContext context, AppLocalizations t) {
    final controller = TextEditingController(text: widget.controller.note);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: Text(t.addNote, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: t.noteHint,
            hintStyle: const TextStyle(color: Colors.white70),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel, style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              widget.controller.setNote(controller.text);
              Navigator.pop(context);
            },
            child: Text(t.save, style: const TextStyle(color: Color(0xFF3A7BFF))),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, AppLocalizations t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.featureComingSoon), backgroundColor: Colors.blue),
    );
  }
}