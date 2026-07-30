import 'package:flutter/material.dart';

class AccountDetailsSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController balanceController;
  final TextEditingController notesController;

  final bool isEditMode;
  final String selectedCurrency;

  const AccountDetailsSection({
    super.key,
    required this.nameController,
    required this.balanceController,
    required this.notesController,
    required this.isEditMode,
    required this.selectedCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Account Name',
            labelStyle: TextStyle(color: Colors.white54),
            hintText: 'e.g., My Bank Account',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter account name';
            }
            return null;
          },
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: balanceController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: isEditMode ? 'Current Balance' : 'Initial Balance',
            labelStyle: const TextStyle(color: Colors.white54),
            prefixText: '$selectedCurrency ',
            prefixStyle: const TextStyle(color: Colors.white54),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          validator: (v) {
            if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Text('Currency', style: TextStyle(color: Colors.white54)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  selectedCurrency,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: notesController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
