// lib/widgets/expense_entry/account_card.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AccountCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String balance;
  final bool selected;
  final VoidCallback onTap;

  const AccountCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.balance,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? iconColor.withOpacity(0.15)
              : AppColors.cardSecondary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? iconColor : Colors.white.withOpacity(0.08),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: iconColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    balance,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.60),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                Icons.check_circle_rounded,
                color: iconColor,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
