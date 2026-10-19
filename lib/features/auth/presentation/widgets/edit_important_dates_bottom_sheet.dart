import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../domain/entities/family_entity.dart';
import '../cubit/family_cubit.dart';

/// Modal Bottom Sheet untuk mengatur tanggal pernikahan dan ulang tahun suami & istri
class EditImportantDatesBottomSheet extends StatefulWidget {
  final FamilyEntity family;

  const EditImportantDatesBottomSheet({
    super.key,
    required this.family,
  });

  static Future<void> show(BuildContext context, {required FamilyEntity family}) {
    final cubit = context.read<FamilyCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: EditImportantDatesBottomSheet(family: family),
      ),
    );
  }

  @override
  State<EditImportantDatesBottomSheet> createState() => _EditImportantDatesBottomSheetState();
}

class _EditImportantDatesBottomSheetState extends State<EditImportantDatesBottomSheet> {
  DateTime? _weddingDate;
  DateTime? _husbandBirthday;
  DateTime? _wifeBirthday;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _weddingDate = widget.family.weddingDate;
    _husbandBirthday = widget.family.husbandBirthday;
    _wifeBirthday = widget.family.wifeBirthday;
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime? currentDate,
    required ValueChanged<DateTime?> onSelected,
    required String helpText,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime(2020, 1, 1),
      firstDate: firstDate ?? DateTime(1940),
      lastDate: lastDate ?? DateTime.now(),
      helpText: helpText,
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentTerracotta,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _saveDates() async {
    final cubit = context.read<FamilyCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isLoading = true);

    try {
      await cubit.updateFamilyDates(
        weddingDate: _weddingDate,
        husbandBirthday: _husbandBirthday,
        wifeBirthday: _wifeBirthday,
        updateWeddingDate: true,
        updateHusbandBirthday: true,
        updateWifeBirthday: true,
      );

      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Tanggal spesial keluarga berhasil disimpan! 💍🎂'),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan tanggal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.bottomSheetRadius,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Judul
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('💍', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hari Spesial & Tanggal Penting',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Atur tanggal pernikahan dan ulang tahun bersama',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 1. Tanggal Pernikahan
            _buildDateField(
              emoji: '💍',
              title: 'Tanggal Pernikahan',
              subtitle: 'Momen berharga hari pernikahan Anda berdua',
              date: _weddingDate,
              onTap: () {
                _pickDate(
                  context: context,
                  currentDate: _weddingDate,
                  helpText: 'PILIH TANGGAL PERNIKAHAN',
                  onSelected: (date) => setState(() => _weddingDate = date),
                );
              },
              onClear: _weddingDate != null
                  ? () => setState(() => _weddingDate = null)
                  : null,
            ),
            const SizedBox(height: 14),

            // 2. Ulang Tahun Suami
            _buildDateField(
              emoji: '👨',
              title: 'Ulang Tahun Suami',
              subtitle: 'Tanggal lahir suami',
              date: _husbandBirthday,
              onTap: () {
                _pickDate(
                  context: context,
                  currentDate: _husbandBirthday,
                  helpText: 'PILIH ULANG TAHUN SUAMI',
                  onSelected: (date) => setState(() => _husbandBirthday = date),
                );
              },
              onClear: _husbandBirthday != null
                  ? () => setState(() => _husbandBirthday = null)
                  : null,
            ),
            const SizedBox(height: 14),

            // 3. Ulang Tahun Istri
            _buildDateField(
              emoji: '👩',
              title: 'Ulang Tahun Istri',
              subtitle: 'Tanggal lahir istri',
              date: _wifeBirthday,
              onTap: () {
                _pickDate(
                  context: context,
                  currentDate: _wifeBirthday,
                  helpText: 'PILIH ULANG TAHUN ISTRI',
                  onSelected: (date) => setState(() => _wifeBirthday = date),
                );
              },
              onClear: _wifeBirthday != null
                  ? () => setState(() => _wifeBirthday = null)
                  : null,
            ),
            const SizedBox(height: 28),

            // Tombol Simpan
            PrimaryButton(
              text: _isLoading ? 'Menyimpan...' : 'Simpan Tanggal Spesial 💖',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _saveDates,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String emoji,
    required String title,
    required String subtitle,
    required DateTime? date,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final hasDate = date != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDate ? AppColors.accentTerracotta.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasDate
                            ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date)
                            : subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: hasDate ? FontWeight.w700 : FontWeight.w500,
                          color: hasDate ? AppColors.accentTerracotta : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasDate && onClear != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    tooltip: 'Hapus Tanggal',
                    onPressed: onClear,
                  )
                else
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: AppColors.accentTerracotta,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
