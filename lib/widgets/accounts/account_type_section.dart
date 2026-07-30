import 'package:flutter/material.dart';
import 'package:wafferly/l10n/app_localizations.dart';
import '../../utils/account_type_helper.dart';
import '../shared/adaptive_wrap_grid.dart';
import 'package:wafferly/models/enums/account_type_option.dart';

class AccountTypeSection extends StatelessWidget {
  final List<AccountTypeOption> types;
  final String selectedType;
  final bool isEditMode;
  final AppLocalizations t;
  final ValueChanged<String> onChanged;

  const AccountTypeSection({
    super.key,
    required this.types,
    required this.selectedType,
    required this.isEditMode,
    required this.t,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 400 ? 2 : 4;

    return AdaptiveWrapGrid(
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final isSelected = selectedType == type.id;

        return GestureDetector(
          onTap: () {
            if (isEditMode &&
                selectedType.isNotEmpty &&
                selectedType != type.id) {
              return;
            }

            onChanged(type.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? type.color.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? type.color : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: type.color.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: SizedBox(
              height: 110,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type.icon,
                    color: isSelected ? type.color : Colors.white54,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getAccountTypeDisplayName(type.id, t),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? type.color : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
