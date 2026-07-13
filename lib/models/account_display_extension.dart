// lib/models/account_display_extension.dart

import 'package:flutter/material.dart';
import 'account.dart';
import 'account_display_config.dart';
import '../theme/app_colors.dart';

extension AccountDisplayExtension on Account {
  AccountDisplayConfig get display {
    // TODO: Change to Enum-based switch to avoid String coupling
    switch (type) {
      case 'cash':
        return const AccountDisplayConfig(
          icon: Icons.payments_rounded,
          color: AppColors.accountCash,
        );
      case 'wallet':
        return const AccountDisplayConfig(
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.accountWallet,
        );
      case 'bank':
        return const AccountDisplayConfig(
          icon: Icons.account_balance_rounded,
          color: AppColors.accountBank,
        );
      case 'saving':
        return const AccountDisplayConfig(
          icon: Icons.savings_rounded,
          color: AppColors.accountSaving,
        );
      case 'credit':
        return const AccountDisplayConfig(
          icon: Icons.credit_card_rounded,
          color: AppColors.accountCredit,
        );
      default:
        return const AccountDisplayConfig(
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.grey,
        );
    }
  }
}
