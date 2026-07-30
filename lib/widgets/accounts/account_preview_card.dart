import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountPreviewCard extends StatelessWidget {
  final String accountName;
  final String? iconAsset;
  final String accountType;
  final String currency;
  final String balance;

  const AccountPreviewCard({
    super.key,
    required this.accountName,
    required this.iconAsset,
    required this.accountType,
    required this.currency,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = accountName.trim().isEmpty
        ? 'New Account'
        : accountName;

    final displayBalance = balance.trim().isEmpty ? '0' : balance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: iconAsset != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(iconAsset!),
                  )
                : const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white70,
                  ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$displayBalance $currency',
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 4),

                Text(
                  accountType,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
