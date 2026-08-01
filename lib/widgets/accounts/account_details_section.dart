import 'package:flutter/material.dart';
import 'package:wafferly/widgets/shared/wafferly_text_field.dart';
import 'package:wafferly/theme/responsive_metrics.dart';

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
    final metrics = ResponsiveMetrics.of(context);

    return Column(
      children: [
        WafferlyTextField(
          controller: nameController,
          label: 'Account Name',
          hint: 'e.g., My Bank Account',
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter account name';
            }
            return null;
          },
        ),
        SizedBox(height: metrics.space.lg),

        WafferlyTextField(
          controller: balanceController,
          label: isEditMode ? 'Current Balance' : 'Initial Balance',

          prefixText: '$selectedCurrency ',

          keyboardType: TextInputType.number,

          validator: (v) {
            if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
              return 'Please enter a valid number';
            }

            return null;
          },
        ),
        SizedBox(height: metrics.space.lg),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Text('Currency', style: TextStyle(color: Colors.white54)),
              const SizedBox(width: 16),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.space.sm,
                  vertical: metrics.space.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(metrics.radius.sm),
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

        SizedBox(height: metrics.space.lg),

        WafferlyTextField(
          controller: notesController,
          label: 'Notes (Optional)',
          minLines: 1,
          maxLines: 1,
        ),
      ],
    );
  }
}
