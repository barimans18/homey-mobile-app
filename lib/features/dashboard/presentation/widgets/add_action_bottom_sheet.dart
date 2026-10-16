import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';

/// Modal Bottom Sheet "Mau tambah apa nih?" saat FAB tengah ditekan
class AddActionBottomSheet extends StatelessWidget {
  final VoidCallback? onAddFinance;
  final VoidCallback? onAddTask;
  final VoidCallback? onAddMeal;

  const AddActionBottomSheet({
    super.key,
    this.onAddFinance,
    this.onAddTask,
    this.onAddMeal,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAddFinance,
    VoidCallback? onAddTask,
    VoidCallback? onAddMeal,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.bottomSheetRadius,
      ),
      builder: (context) => AddActionBottomSheet(
        onAddFinance: onAddFinance,
        onAddTask: onAddTask,
        onAddMeal: onAddMeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle Indicator
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Judul Modal
            Text(
              'Mau tambah apa nih?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 20),

            // Option 1: Catat Pengeluaran
            _buildActionItem(
              context: context,
              title: 'Catat Pengeluaran',
              subtitle: 'Input pengeluaran atau pemasukan baru',
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppColors.accentTerracotta,
              iconBgColor: AppColors.accentTerracotta.withValues(alpha: 0.15),
              onTap: () {
                Navigator.pop(context);
                onAddFinance?.call();
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Tambah Agenda / Tugas
            _buildActionItem(
              context: context,
              title: 'Tambah Agenda/Tugas',
              subtitle: 'Buat jadwal atau to-do list bersama',
              icon: Icons.event_available_rounded,
              iconColor: AppColors.accentGreen,
              iconBgColor: AppColors.accentGreen.withValues(alpha: 0.18),
              onTap: () {
                Navigator.pop(context);
                onAddTask?.call();
              },
            ),
            const SizedBox(height: 12),

            // Option 3: Rencana Menu Makan
            _buildActionItem(
              context: context,
              title: 'Rencana Menu Makan',
              subtitle: 'Catat ide masakan untuk hari ini',
              icon: Icons.restaurant_rounded,
              iconColor: const Color(0xFFC99238),
              iconBgColor: AppColors.accentYellow.withValues(alpha: 0.35),
              onTap: () {
                Navigator.pop(context);
                onAddMeal?.call();
              },
            ),
            const SizedBox(height: 20),

            // Tombol Batal
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.buttonRadius,
                  ),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.cardRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
