import 'package:flutter/material.dart';

/// Aturan border radius membulat ekstrem sesuai design_system.md
class AppRadii {
  AppRadii._();

  /// Sudut untuk Card dan Button (16 - 24)
  static const double card = 20.0;
  static const double button = 20.0;
  static const double chip = 16.0;

  /// Sudut untuk Container luar & Bottom Sheet (32 - 40)
  static const double bottomSheet = 32.0;
  static const double outerContainer = 36.0;

  // BorderRadius helpers
  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius buttonRadius = BorderRadius.circular(button);
  static final BorderRadius chipRadius = BorderRadius.circular(chip);
  static final BorderRadius bottomSheetRadius = const BorderRadius.vertical(
    top: Radius.circular(bottomSheet),
  );
  static final BorderRadius outerContainerRadius = BorderRadius.circular(outerContainer);
}
