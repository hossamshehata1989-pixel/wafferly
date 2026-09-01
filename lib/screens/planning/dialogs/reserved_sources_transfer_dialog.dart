import 'package:flutter/material.dart';
import '../../../models/account.dart';
import '../../../models/goal_funding_source.dart';

typedef ReservedSourceTransferHandler = Future<void> Function(
  GoalFundingSource source,
  String savingAccountId,
);

/// Shows every reserved source separately.
///
/// Each source has its own saving-account selector and Transfer button.
/// Transfer All is enabled only when every remaining source has a saving
/// account selected.
Future<bool> showReservedSourcesTransferDialog({
  required BuildContext context,
  required List<GoalFundingSource> fundingSources,
  required List<Account> savingAccounts,
  required ReservedSourceTransferHandler onTransfer,
}) async {
  if (fundingSources.isEmpty || savingAccounts.isEmpty) return false;

  final selectedSavingIds = <String, String?>{
    for (final source in fundingSources) source.accountId: null,
  };
  final transferred = <String>{};

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1B1D22),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final remaining = fundingSources
              .where((source) => !transferred.contains(source.accountId))
              .toList();
          final allSelected = remaining.isNotEmpty &&
              remaining.every((source) =>
                  selectedSavingIds[source.accountId] != null);

          Future<void> transferOne(GoalFundingSource source) async {
            final savingId = selectedSavingIds[source.accountId];
            if (savingId == null) return;

            try {
              await onTransfer(source, savingId);
              if (!context.mounted) return;
              setState(() => transferred.add(source.accountId));

              if (transferred.length == fundingSources.length) {
                Navigator.pop(context, true);
              }
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transfer failed. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          Future<void> transferAll() async {
            if (!allSelected) return;

            final sources = fundingSources
                .where((source) => !transferred.contains(source.accountId))
                .toList();

            try {
              for (final source in sources) {
                final savingId = selectedSavingIds[source.accountId];
                if (savingId == null) return;
                await onTransfer(source, savingId);
                if (!context.mounted) return;
                setState(() => transferred.add(source.accountId));
              }
              if (context.mounted) Navigator.pop(context, true);
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('One or more transfers failed.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Transfer To Saving',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Choose a saving account for each reserved source.',
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 18),
                    for (final source in fundingSources)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      source.accountName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${source.amount.toStringAsFixed(0)} EGP',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (transferred.contains(source.accountId))
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      'Transferred',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ],
                                )
                              else ...[
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      selectedSavingIds[source.accountId],
                                  decoration: const InputDecoration(
                                    labelText: 'Saving Account',
                                  ),
                                  items: savingAccounts.map((account) {
                                    return DropdownMenuItem<String>(
                                      value: account.id,
                                      child: Text(account.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSavingIds[source.accountId] = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        selectedSavingIds[source.accountId] == null
                                            ? null
                                            : () => transferOne(source),
                                    icon: const Icon(Icons.swap_horiz),
                                    label: const Text('Transfer'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: allSelected ? transferAll : null,
                        icon: const Icon(Icons.done_all),
                        label: const Text('Transfer All'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Back'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  return result == true;
}
