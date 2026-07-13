// lib/widgets/bottom_sheet/sheet_header.dart

import 'package:flutter/material.dart';

class SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  final IconData? icon;

  const SheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white70, size: 28),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              iconSize: 20, // 🔹 تصغير حجم الأيقونة
              visualDensity: VisualDensity.compact, // 🔹 تقليل الكثافة
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}
