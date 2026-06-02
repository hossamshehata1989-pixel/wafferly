import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/accounts/add_account/add_account_screen.dart';
import '../../models/enums/section_type.dart';

Future<void> showAccountPickerSheet(
  BuildContext context,
  TransactionEntryController controller,
) async {
  final accounts = controller.availableAccounts;

  if (accounts.isEmpty) {
    final create = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No accounts found'),
        content: const Text('You need to create an account first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );

    if (create == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddAccountScreen(sectionType: SectionType.asset),
        ),
      );

      if (context.mounted) {
        await showAccountPickerSheet(context, controller);
      }
    }

    return;
  }

  await showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.selectAccount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Flexible(
            child: ListView(
              children: accounts
                  .map(
                    (acc) => ListTile(
                      title: Text(
                        acc.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        acc.type,
                        style: const TextStyle(color: Colors.white54),
                      ),
                      onTap: () {
                        controller.selectAccount(acc.id, acc.name);

                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),

          const Divider(color: Colors.white24),

          const ListTile(
            leading: Icon(Icons.check, color: Colors.white),
            title: Text(
              'Remember last account',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}
