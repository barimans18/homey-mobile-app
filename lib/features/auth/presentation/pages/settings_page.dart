import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/custom_app_bar.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/session_storage_service.dart';
import '../cubit/family_cubit.dart';
import '../cubit/family_state.dart';
import '../widgets/family_pairing_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Pengaturan ⚙️',
        subtitle: 'Keluarga, pairing & preferensi akun',
      ),
      body: BlocBuilder<FamilyCubit, FamilyState>(
        builder: (context, state) {
          if (state is FamilyLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentTerracotta),
            );
          }

          if (state is FamilyError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<FamilyCubit>().loadFamilyData(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final loadedState = state is FamilyLoaded
              ? state
              : null;

          final profile = loadedState?.profile;
          final family = loadedState?.family;
          final members = loadedState?.members ?? [];

          final isHusband = profile?.role.toLowerCase() == 'suami';
          final roleLabel = isHusband ? 'Suami 👨' : 'Istri 👩';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Kartu Profil Pengguna
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.cardRadius,
                    boxShadow: AppShadows.card,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isHusband
                              ? AppColors.accentTerracotta.withValues(alpha: 0.15)
                              : AppColors.accentGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            isHusband ? '👨' : '👩',
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.fullName ?? 'Pengguna Homey',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isHusband
                                    ? AppColors.accentTerracotta.withValues(alpha: 0.12)
                                    : AppColors.accentGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                roleLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isHusband
                                      ? AppColors.accentTerracotta
                                      : AppColors.accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tombol Ganti Peran
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                        ),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text(
                          'Ubah',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          final newRole = isHusband ? 'istri' : 'suami';
                          context.read<FamilyCubit>().updateRole(newRole);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Section Family Pairing (TEMPAT KODE KELUARGA)
                Text(
                  'Keluarga & Sinkronisasi Pasangan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.cardRadius,
                    boxShadow: AppShadows.card,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (family != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.home_rounded,
                                color: AppColors.accentGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                family.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Terhubung',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Box Kode Keluarga Unik
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'KODE KELUARGA ANDA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    family.inviteCode,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.accentTerracotta,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Tombol Salin Kode
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.textPrimary,
                                  elevation: 0,
                                  side: const BorderSide(color: AppColors.border),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 15),
                                label: const Text(
                                  'Salin Kode',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: family.inviteCode),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kode Keluarga berhasil disalin!'),
                                      backgroundColor: AppColors.accentGreen,
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Bagikan kode di atas kepada pasangan Anda agar seluruh catatan kas dan agenda harian tersinkronisasi otomatis.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Anggota Keluarga yang Terhubung
                        const Text(
                          'Anggota Keluarga:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (members.isEmpty)
                          const Text(
                            'Belum ada data anggota lain.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          )
                        else
                          ...members.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Text(
                                    m.role.toLowerCase() == 'suami' ? '👨' : '👩',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    m.fullName ?? (m.role.toLowerCase() == 'suami' ? 'Suami' : 'Istri'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${m.role.toUpperCase()})',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Tombol Ganti / Input Kode Keluarga Lain
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          icon: const Icon(Icons.swap_calls_rounded, size: 18),
                          label: const Text(
                            'Pindah ke Keluarga Lain (Input Kode)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          onPressed: () => FamilyPairingDialog.show(context),
                        ),
                      ] else ...[
                        // Keadaan belum terhubung ke keluarga
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accentYellow.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.link_off_rounded,
                                color: AppColors.accentTerracotta,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Belum Terhubung ke Keluarga',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Masukkan kode keluarga pasangan untuk mulai sinkronisasi.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentTerracotta,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            minimumSize: const Size(double.infinity, 46),
                          ),
                          icon: const Icon(Icons.key_rounded, size: 18),
                          label: const Text(
                            'Input Kode Keluarga Pasangan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () => FamilyPairingDialog.show(context),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Status Koneksi Backend Database (Supabase)
                Text(
                  'Koneksi Cloud & Keamanan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.cardRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.cloud_done_rounded,
                        color: AppColors.accentGreen,
                        title: 'Database Supabase',
                        subtitle: 'cyjsjvhubmwhoewkvrez (Aktif)',
                      ),
                      const Divider(color: AppColors.border, height: 20),
                      _buildInfoRow(
                        icon: Icons.sync_lock_rounded,
                        color: AppColors.accentTerracotta,
                        title: 'Enkripsi & RLS',
                        subtitle: 'Row Level Security Aktif per Family',
                      ),
                      const Divider(color: AppColors.border, height: 20),
                      _buildInfoRow(
                        icon: Icons.bolt_rounded,
                        color: AppColors.accentYellow,
                        title: 'Real-time WebSocket',
                        subtitle: 'Publikasi Realtime Aktif (< 2s sync)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 4. Tombol Logout / Keluar
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Keluar dari Akun',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
        title: const Text('Keluar dari Rumah?'),
        content: const Text(
          'Sesi Anda di perangkat ini akan direset. Anda dapat masuk kembali dengan memilih peran atau memasukkan kode keluarga.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await sl<SessionStorageService>().clearSession();
              if (context.mounted) {
                context.go(AppRouter.login);
              }
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
