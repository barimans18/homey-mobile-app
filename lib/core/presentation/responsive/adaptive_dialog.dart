import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_radii.dart';
import '../../constants/app_shadows.dart';
import 'responsive_layout.dart';

/// Helper untuk menampilkan modal yang adaptif:
/// - Pada Mobile (< 768px): Ditampilkan sebagai Modal Bottom Sheet.
/// - Pada Desktop/Web/Tablet (>= 768px): Ditampilkan sebagai Centered Dialog dengan batas lebar.
class AdaptiveModal {
  AdaptiveModal._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double maxWidth = 540.0,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    if (context.isWideScreen) {
      return showDialog<T>(
        context: context,
        barrierDismissible: isDismissible,
        barrierColor: AppColors.textPrimary.withValues(alpha: 0.45),
        builder: (dialogContext) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.bottomSheetRadius,
                    boxShadow: AppShadows.soft,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: builder(dialogContext),
                ),
              ),
            ),
          );
        },
      );
    } else {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.bottomSheetRadius,
        ),
        builder: builder,
      );
    }
  }
}
