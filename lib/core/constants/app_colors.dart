import 'package:flutter/material.dart';

/// Palet warna resmi Homey berdasarkan design_system.md
class AppColors {
  AppColors._();

  /// Background: #FDFBF7 (Warm off-white)
  static const Color background = Color(0xFFFDFBF7);

  /// Text Primary: #3D405B (Soft Navy/Grey, hindari hitam pekat)
  static const Color textPrimary = Color(0xFF3D405B);

  /// Text Muted: #9CA3AF (Gray untuk subtitle)
  static const Color textMuted = Color(0xFF9CA3AF);

  /// Accent Green (Budget/Success): #81B29A (Sage green)
  static const Color accentGreen = Color(0xFF81B29A);

  /// Accent Terracotta (Primary Action/Buttons): #E07A5F
  static const Color accentTerracotta = Color(0xFFE07A5F);

  /// Accent Yellow (Warning/Kids/Meals): #F2CC8F
  static const Color accentYellow = Color(0xFFF2CC8F);

  /// Soft surface container
  static const Color surface = Colors.white;

  /// Card border outline
  static const Color border = Color(0xFFEFECE6);

  /// Error state
  static const Color error = Color(0xFFE05353);
}
