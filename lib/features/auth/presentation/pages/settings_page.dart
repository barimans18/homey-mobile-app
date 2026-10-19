import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../widgets/edit_profile_bottom_sheet.dart';
import '../widgets/edit_important_dates_bottom_sheet.dart';
import '../widgets/profile_photo_view_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _obscurePin = true;

  void _showChangePinDialog(BuildContext context, String currentPin) {
    final familyCubit = context.read<FamilyCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final pinController = TextEditingController(text: currentPin);
    bool obscure = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return BlocProvider.value(
          value: familyCubit,
          child: StatefulBuilder(
            builder: (innerCtx, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
                title: const Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, color: AppColors.accentTerracotta),
                    SizedBox(width: 8),
                    Text('Ubah PIN Keluarga', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan 6 digit angka PIN baru untuk keluarga Anda:',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: obscure,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                      decoration: InputDecoration(
                        hintText: '123456',
                        counterText: '',
                        prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.accentTerracotta),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            setDialogState(() => obscure = !obscure);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTerracotta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final newPin = pinController.text.trim();
                      if (newPin.length != 6 || int.tryParse(newPin) == null) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('PIN harus berupa 6 digit angka'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(dialogCtx);
                      familyCubit.updateFamilyPin(newPin);
                    },
                    child: const Text('Simpan PIN'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Pengaturan ⚙️',
        subtitle: 'Keluarga, pairing & preferensi akun',
      ),
      body: BlocConsumer<FamilyCubit, FamilyState>(
        listener: (context, state) {
          if (state is FamilyLoaded && state.notificationMessage != null) {
            final isSuccess = state.notificationMessage!.contains('berhasil') ||
                state.notificationMessage!.contains('Yeay');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.notificationMessage!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: isSuccess ? AppColors.accentGreen : AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
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
                // 1. Kartu Profil Pengguna (Simpel & Elegan)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.cardRadius,
                    boxShadow: AppShadows.card,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      // Avatar (Ketuk untuk melihat foto dalam ukuran penuh)
                      GestureDetector(
                        onTap: () {
                          if (profile != null) {
                            ProfilePhotoViewDialog.show(context, profile: profile);
                          }
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isHusband
                                ? AppColors.accentTerracotta.withValues(alpha: 0.15)
                                : AppColors.accentGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isHusband
                                  ? AppColors.accentTerracotta.withValues(alpha: 0.4)
                                  : AppColors.accentGreen.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: (profile?.avatarUrl != null &&
                                    profile!.avatarUrl!.isNotEmpty)
                                ? Image.network(
                                    profile.avatarUrl!,
                                    fit: BoxFit.cover,
                                    width: 52,
                                    height: 52,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        isHusband ? '👨' : '👩',
                                        style: const TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      isHusband ? '👨' : '👩',
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile?.fullName ?? 'Pengguna Homey',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHusband
                                        ? AppColors.accentTerracotta.withValues(alpha: 0.12)
                                        : AppColors.accentGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
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
                                if (family?.weddingDate != null)
                                  Text(
                                    '💍 ${DateFormat('d MMM yyyy', 'id_ID').format(family!.weddingDate!)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Edit Profil
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentTerracotta,
                          side: BorderSide(
                            color: AppColors.accentTerracotta.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          if (profile != null) {
                            EditProfileBottomSheet.show(context, profile: profile);
                          }
                        },
                        child: const Text(
                          'Edit Profil',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Section Tanggal Penting (Ringkas, Rapi & Elegan)
                if (family != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadii.cardRadius,
                      boxShadow: AppShadows.card,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Text('💍', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 6),
                                Text(
                                  'Tanggal Penting',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => EditImportantDatesBottomSheet.show(
                                context,
                                family: family,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 13,
                                      color: AppColors.accentTerracotta,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ubah',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accentTerracotta,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildDateLine(
                          emoji: '💍',
                          label: 'Hari Pernikahan',
                          value: family.weddingDate != null
                              ? DateFormat('d MMMM yyyy', 'id_ID').format(family.weddingDate!)
                              : 'Belum diatur',
                        ),
                        const SizedBox(height: 6),
                        _buildDateLine(
                          emoji: '👨',
                          label: 'Ulang Tahun Suami',
                          value: family.husbandBirthday != null
                              ? DateFormat('d MMMM yyyy', 'id_ID').format(family.husbandBirthday!)
                              : 'Belum diatur',
                        ),
                        const SizedBox(height: 6),
                        _buildDateLine(
                          emoji: '👩',
                          label: 'Ulang Tahun Istri',
                          value: family.wifeBirthday != null
                              ? DateFormat('d MMMM yyyy', 'id_ID').format(family.wifeBirthday!)
                              : 'Belum diatur',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

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
                        const SizedBox(height: 12),

                        // Box PIN Keluarga Unik (6 Digit)
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
                                    'PIN KELUARGA (6 DIGIT)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        _obscurePin ? '••••••' : family.pin,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary,
                                          letterSpacing: 3,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => setState(() => _obscurePin = !_obscurePin),
                                        child: Icon(
                                          _obscurePin
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 18,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Tombol Ubah PIN
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accentTerracotta),
                                tooltip: 'Ubah PIN',
                                onPressed: () => _showChangePinDialog(context, family.pin),
                              ),
                              // Tombol Salin PIN
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
                                  'Salin PIN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: family.pin),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('PIN Keluarga berhasil disalin!'),
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
                          'Bagikan Kode Keluarga dan PIN 6 digit di atas kepada pasangan Anda agar dapat bergabung dan seluruh catatan tersinkronisasi otomatis.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Anggota Keluarga yang Terhubung
                        Row(
                          children: [
                            const Text(
                              'Anggota Keluarga Terhubung:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentTerracotta.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${members.length} Orang',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentTerracotta,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (members.isEmpty)
                          const Text(
                            'Belum ada data anggota lain.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          )
                        else
                          ...members.map(
                            (m) {
                              final isCurrent = (profile != null && m.id == profile.id) ||
                                  (profile != null &&
                                      m.role.toLowerCase() == profile.role.toLowerCase());

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.surface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrent
                                        ? AppColors.accentTerracotta.withValues(alpha: 0.4)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      m.role.toLowerCase() == 'suami' ? '👨' : '👩',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.fullName ?? (m.role.toLowerCase() == 'suami' ? 'Suami' : 'Istri'),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            m.role.toLowerCase() == 'suami' ? 'Suami' : 'Istri',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? AppColors.accentTerracotta
                                            : AppColors.accentGreen.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isCurrent ? 'Anda' : 'Pasangan',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isCurrent ? Colors.white : AppColors.accentGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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

  Widget _buildDateLine({
    required String emoji,
    required String label,
    required String value,
  }) {
    final isSet = value != 'Belum diatur';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSet ? FontWeight.w700 : FontWeight.w500,
              color: isSet ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
