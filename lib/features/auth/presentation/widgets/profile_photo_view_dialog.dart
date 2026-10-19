import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../domain/entities/family_entity.dart';
import 'edit_profile_bottom_sheet.dart';

/// Dialog untuk melihat foto profil dalam ukuran penuh (Preview Foto)
class ProfilePhotoViewDialog extends StatelessWidget {
  final UserProfileEntity profile;

  const ProfilePhotoViewDialog({super.key, required this.profile});

  static void show(BuildContext context, {required UserProfileEntity profile}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => ProfilePhotoViewDialog(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
    final isHusband = profile.isHusband;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar dengan tombol tutup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      isHusband ? '👨 Suami' : '👩 Istri',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Kontainer Foto
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 420),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.cardRadius,
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: AppRadii.cardRadius,
              child: hasPhoto
                  ? InteractiveViewer(
                      panEnabled: true,
                      minScale: 1.0,
                      maxScale: 3.5,
                      child: Image.network(
                        profile.avatarUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 300,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppColors.accentTerracotta,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      ),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          const SizedBox(height: 16),

          // Nama Pengguna
          Text(
            profile.fullName ?? (isHusband ? 'Suami' : 'Istri'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Opsi Ubah Foto
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
            label: const Text(
              'Ubah Foto di Edit Profil',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            onPressed: () {
              Navigator.pop(context);
              EditProfileBottomSheet.show(context, profile: profile);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    final isHusband = profile.isHusband;
    return Container(
      height: 280,
      width: double.infinity,
      color: isHusband
          ? AppColors.accentTerracotta.withValues(alpha: 0.1)
          : AppColors.accentGreen.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isHusband ? '👨' : '👩',
            style: const TextStyle(fontSize: 84),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada foto profil',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
