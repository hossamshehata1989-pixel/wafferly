// lib/models/account_display_extension.dart

import 'package:flutter/material.dart';

import 'account.dart';
import 'account_display_config.dart';
import '../theme/app_colors.dart';

extension AccountDisplayExtension on Account {
  AccountDisplayConfig get display {
    switch (type) {
      // ========================================================
      // LIQUIDITY
      // ========================================================

      case 'cash':
        return const AccountDisplayConfig(
          icon: Icons.payments_rounded,
          color: AppColors.accountCash,
        );

      case 'bank':
        return const AccountDisplayConfig(
          icon: Icons.account_balance_rounded,
          color: AppColors.accountBank,
        );

      case 'wallet':
        return const AccountDisplayConfig(
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.accountWallet,
        );

      case 'debitCard':
        return const AccountDisplayConfig(
          icon: Icons.credit_card_rounded,
          color: AppColors.accountCredit,
        );

      // ========================================================
      // LIABILITIES
      // ========================================================

      case 'debt':
      case 'moneyBorrowed':
        return const AccountDisplayConfig(
          icon: Icons.money_off_rounded,
          color: AppColors.accountCredit,
        );

      case 'loan':
        return const AccountDisplayConfig(
          icon: Icons.request_quote_rounded,
          color: AppColors.accountCredit,
        );

      case 'creditCard':
        return const AccountDisplayConfig(
          icon: Icons.credit_card_rounded,
          color: AppColors.accountCredit,
        );

      case 'installment':
        return const AccountDisplayConfig(
          icon: Icons.calendar_month_rounded,
          color: AppColors.accountCredit,
        );

      // ========================================================
      // INVESTMENTS
      // ========================================================

      case 'investment':
        return const AccountDisplayConfig(
          icon: Icons.trending_up_rounded,
          color: AppColors.accountSaving,
        );

      case 'gold':
        return const AccountDisplayConfig(
          icon: Icons.workspace_premium_rounded,
          color: AppColors.accountSaving,
        );

      case 'stocks':
        return const AccountDisplayConfig(
          icon: Icons.show_chart_rounded,
          color: AppColors.accountSaving,
        );

      case 'certificates':
        return const AccountDisplayConfig(
          icon: Icons.description_rounded,
          color: AppColors.accountSaving,
        );

      // ========================================================
      // RECEIVABLE
      // ========================================================

      case 'lent':
        return const AccountDisplayConfig(
          icon: Icons.handshake_rounded,
          color: AppColors.accountSaving,
        );

      case 'rosca':
      case 'savingCircle':
        return const AccountDisplayConfig(
          icon: Icons.groups_rounded,
          color: AppColors.accountSaving,
        );

      // ========================================================
      // SAVINGS
      // ========================================================

      case 'realSaving':
      case 'saving':
        return const AccountDisplayConfig(
          icon: Icons.savings_rounded,
          color: AppColors.accountSaving,
        );

      // ========================================================
      // LEGACY ALIASES
      // ========================================================

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