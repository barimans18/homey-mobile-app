import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';

/// Item tugas / agenda di bagian "Fokus Hari Ini"
class FocusTaskItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData subtitleIcon;
  final Color? subtitleColor;
  final bool isCompleted;
  final ValueChanged<bool?> onToggle;

  const FocusTaskItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.subtitleIcon,
    this.subtitleColor,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.cardRadius,
          onTap: () => onToggle(!isCompleted),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Custom Cozy Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.accentTerracotta : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCompleted ? AppColors.accentTerracotta : AppColors.accentTerracotta,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                // Deskripsi Tugas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          decorationColor: AppColors.textMuted,
                          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                        ),
                        child: Text(title),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            subtitleIcon,
                            size: 13,
                            color: subtitleColor ?? AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor ?? AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
