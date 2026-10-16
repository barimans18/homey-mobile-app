import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Soft drop shadows yang lembut dan menyebar sesuai design_system.md
class AppShadows {
  AppShadows._();

  /// Soft drop shadow utama
  /// BoxShadow(color: Color(0xFF3D405B).withOpacity(0.08), blurRadius: 40, offset: Offset(0, 10))
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.08),
      blurRadius: 40,
      offset: const Offset(0, 10),
    ),
  ];

  /// Shadow ringan untuk card
  static final List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  /// Shadow untuk Bottom Navigation Bar
  static final List<BoxShadow> bottomNav = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.07),
      blurRadius: 30,
      offset: const Offset(0, -5),
    ),
  ];
}
