import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_radii.dart';
import '../../constants/app_shadows.dart';

/// Card kustom dengan soft shadow dan rounded border sesuai design_system.md
class CozyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Border? border;
  final bool hasShadow;

  const CozyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.backgroundColor = AppColors.surface,
    this.border,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.cardRadius,
        border: border ?? Border.all(color: AppColors.border, width: 1),
        boxShadow: hasShadow ? AppShadows.card : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.cardRadius,
        child: InkWell(
          borderRadius: AppRadii.cardRadius,
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
