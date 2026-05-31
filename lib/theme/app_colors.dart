// lib/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // =========================
  // Background
  // =========================

  static const Color background = Color(0xFF0B1320);

  static const Color card = Color(0xFF151E2D);

  static const Color cardSecondary = Color(0xFF1C273A);

  // =========================
  // Brand Colors
  // =========================

  static const Color primary = Color(0xFF14B8A6);

  static const Color accent = Color(0xFF67E8F9);

  // =========================
  // Financial Colors
  // =========================

  static const Color income = Color(0xFF22C55E);

  static const Color expense = Color(0xFFFF6B6B);

  static const Color investment = Color(0xFFFFC857);

  static const Color saving = Color(0xFF3B82F6);

  static const Color debt = Color(0xFFFF8A4C);

  // =========================
  // Status Colors
  // =========================

  static const Color success = Color(0xFF22C55E);

  static const Color warning = Color(0xFFFFB020);

  static const Color error = Color(0xFFFF5C5C);

  static const Color inactive = Color(0xFF6B7280);

  // =========================
  // Text
  // =========================

  static const Color textPrimary = Color(0xFFF8FAFC);

  static const Color textSecondary = Color(0xFF94A3B8);

  static const Color textHint = Color(0xFF64748B);

  static const Color textDisabled = Color(0xFF475569);

  // =========================
  // Borders
  // =========================

  static const Color border = Color(0xFF273449);

  // =========================
  // Smart Feed
  // =========================

  static const Color smartFeedStart = Color(0xFF14B8A6);

  static const Color smartFeedEnd = Color(0xFF0EA5E9);

  // =========================
  // Gradients
  // =========================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF67E8F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient investmentGradient = LinearGradient(
    colors: [Color(0xFFFFC857), Color(0xFFFFE08A)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8A80)],
  );

  static const Color inputPanel = Color.fromARGB(255, 80, 106, 146);

  static const Color calculatorButton = Color(0xFF162033);
}
