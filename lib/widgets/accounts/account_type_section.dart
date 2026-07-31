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
    return AdaptiveWrapGrid(
      columns: 4,
      itemCount: types.length,
      itemBuilder: (context, index, itemWidth) {
        final type = types[index];
        final isSelected = selectedType == type.id;

        final iconSize = itemWidth >= 120
            ? 28.0
            : itemWidth >= 100
            ? 24.0
            : itemWidth >= 80
            ? 20.0
            : 18.0;

        final fontSize = itemWidth >= 120
            ? 12.0
            : itemWidth >= 100
            ? 11.0
            : itemWidth >= 80
            ? 10.0
            : 9.0;

        final verticalPadding = itemWidth >= 100 ? 12.0 : 8.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? type.color
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: type.color.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Container(
                constraints: const BoxConstraints(minHeight: 78),
                padding: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type.icon,
                      color: isSelected ? type.color : Colors.white54,
                      size: iconSize,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      getAccountTypeDisplayName(type.id, t),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? type.color : Colors.white70,
                        fontSize: fontSize,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
