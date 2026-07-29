import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'financial_group_assets.dart';
import 'financial_group_visual.dart';
import '../models/enums/section_type.dart';

class FinancialGroupVisualResolver {
  const FinancialGroupVisualResolver._();

  static FinancialGroupVisual resolve(SectionType type) {
    switch (type) {
      case SectionType.liquidity:
        return const FinancialGroupVisual(
          icon: FinancialGroupAssets.liquidityIcon,
          background: FinancialGroupAssets.liquidityBackground,
          color: AppColors.accountCash,
        );

      case SectionType.savings:
        return const FinancialGroupVisual(
          icon: FinancialGroupAssets.savingsIcon,
          background: FinancialGroupAssets.savingsBackground,
          color: AppColors.accountSaving,
        );

      case SectionType.investments:
        return const FinancialGroupVisual(
          icon: FinancialGroupAssets.investmentsIcon,
          background: FinancialGroupAssets.investmentsBackground,
          color: AppColors.investment,
        );

      case SectionType.liabilities:
        return const FinancialGroupVisual(
          icon: FinancialGroupAssets.liabilitiesIcon,
          background: FinancialGroupAssets.liabilitiesBackground,
          color: AppColors.debt,
        );

      case SectionType.receivable:
        return const FinancialGroupVisual(
          icon: FinancialGroupAssets.receivableIcon,
          background: FinancialGroupAssets.receivableBackground,
          color: AppColors.accountWallet,
        );
    }
  }
}
