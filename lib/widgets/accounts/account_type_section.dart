import 'package:flutter/material.dart';
import 'package:wafferly/l10n/app_localizations.dart';

import '../../utils/account_type_helper.dart';
import '../shared/adaptive_wrap_grid.dart';
import 'package:wafferly/models/enums/account_type_option.dart';
import 'package:wafferly/theme/responsive_metrics.dart';

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
    final metrics = ResponsiveMetrics.of(context);
    return AdaptiveWrapGrid(
      columns: 4,
      itemCount: types.length,
      itemBuilder: (context, index, itemWidth) {
        final type = types[index];
        final isSelected = selectedType == type.id;

        final iconSize = metrics.icon.medium;

        final fontSize = metrics.typography.caption;

        final verticalPadding = metrics.space.sm;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(metrics.radius.lg),
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
                          blurRadius: metrics.size(8),
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: metrics.card.accountTypeHeight,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: metrics.space.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type.icon,
                      color: isSelected ? type.color : Colors.white54,
                      size: iconSize,
                    ),
                    SizedBox(height: metrics.space.xs),
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
