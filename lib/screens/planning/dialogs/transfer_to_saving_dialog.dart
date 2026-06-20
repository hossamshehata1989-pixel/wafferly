// lib/screens/planning/dialogs/transfer_to_saving_dialog.dart

import 'package:flutter/material.dart';
import '../../../models/transfer_to_saving_result.dart';
import '../../../models/account.dart';

Future<TransferToSavingResult?> showTransferToSavingDialog({
  required BuildContext context,
  required double availableAmount,
  required List<Account> savingAccounts,
  bool allowPartialTransfer = true,
}) async {
  double percentage = 100;
  bool isValid = true;
  String? selectedSavingId;

  final controller = TextEditingController(
    text: availableAmount.toStringAsFixed(2),
  );

  if (savingAccounts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No saving accounts available. Please create one first.'),
        backgroundColor: Colors.orange,
      ),
    );
    return null;
  }

  if (selectedSavingId == null && savingAccounts.isNotEmpty) {
    selectedSavingId = savingAccounts.first.id;
  }

  return await showModalBottomSheet<TransferToSavingResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1B1D22),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Transfer To Saving',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Available Reserved',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                const SizedBox(height: 4),
                Text(
                  '${availableAmount.toStringAsFixed(2)} EGP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: selectedSavingId,
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
                      selectedSavingId = value;
                    });
                  },
                ),
                const SizedBox(height: 24),

                if (allowPartialTransfer) ...[
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        final amount = double.tryParse(value) ?? 0;

                        if (amount <= 0) {
                          isValid = false;
                          return;
                        }

                        if (amount > availableAmount) {
                          controller.text = availableAmount.toStringAsFixed(0);
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                        }

                        final safeAmount = amount > availableAmount
                            ? availableAmount
                            : amount;

                        percentage = (safeAmount / availableAmount) * 100;

                        isValid = true;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      errorText: isValid
                          ? null
                          : 'Amount must be greater than zero',
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    '${percentage.toInt()}%',
                    style: const TextStyle(color: Colors.white),
                  ),

                  Slider(
                    value: percentage,
                    min: 0,
                    max: 100,
                    onChanged: (value) {
                      setState(() {
                        percentage = value;
                        final amount = (availableAmount * percentage) / 100;
                        controller.text = amount.toStringAsFixed(2);
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    children: [
                      _quickPercent(
                        '25%',
                        25,
                        availableAmount,
                        setState,
                        controller,
                        (v) => percentage = v,
                        () => isValid = true,
                      ),
                      _quickPercent(
                        '50%',
                        50,
                        availableAmount,
                        setState,
                        controller,
                        (v) => percentage = v,
                        () => isValid = true,
                      ),
                      _quickPercent(
                        '75%',
                        75,
                        availableAmount,
                        setState,
                        controller,
                        (v) => percentage = v,
                        () => isValid = true,
                      ),
                      _quickPercent(
                        '100%',
                        100,
                        availableAmount,
                        setState,
                        controller,
                        (v) => percentage = v,
                        () => isValid = true,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selectedSavingId != null
                        ? () {
                            final amount = allowPartialTransfer
                                ? (double.tryParse(controller.text) ?? 0)
                                : availableAmount;

                            if (amount <= 0 || amount > availableAmount) {
                              return;
                            }

                            Navigator.pop(
                              context,
                              TransferToSavingResult(
                                savingAccountId: selectedSavingId!,
                                amount: amount,
                              ),
                            );
                          }
                        : null,
                    child: const Text('Transfer'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _quickPercent(
  String label,
  double value,
  double availableAmount,
  StateSetter setState,
  TextEditingController controller,
  Function(double) onPercentChanged,
  Function() markValid,
) {
  return OutlinedButton(
    onPressed: () {
      setState(() {
        onPercentChanged(value);
        markValid();
        final amount = (availableAmount * value) / 100;
        controller.text = amount.toStringAsFixed(2);
      });
    },
    child: Text(label),
  );
}
