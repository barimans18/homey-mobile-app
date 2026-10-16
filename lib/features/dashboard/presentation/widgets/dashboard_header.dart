import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';

/// Header beranda dengan tanggal hari ini, sapaan hangat personal, dan avatar keluarga
class DashboardHeader extends StatelessWidget {
  final String greetingName;
  final VoidCallback? onProfileTap;

  const DashboardHeader({
    super.key,
    this.greetingName = 'Pasutri',
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Format tanggal: misal "Jumat, 16 Okt 2026"
    final dateFormatted = DateFormat('EEEE, d MMM y', 'id_ID').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateFormatted,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Halo, $greetingName! 👋',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
          ],
        ),
        // Avatar Keluarga / Profil Pasangan
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentTerracotta.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: AppShadows.card,
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: AppColors.accentTerracotta,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}
