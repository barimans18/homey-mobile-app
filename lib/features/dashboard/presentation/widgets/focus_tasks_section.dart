import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'focus_task_item.dart';

/// Model item dummy untuk pratinjau Fokus Hari Ini
class FocusTaskData {
  final String id;
  final String title;
  final String subtitle;
  final IconData subtitleIcon;
  final Color? subtitleColor;
  bool isCompleted;

  FocusTaskData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.subtitleIcon,
    this.subtitleColor,
    this.isCompleted = false,
  });
}

/// Bagian "Fokus Hari Ini" di Tab Beranda
class FocusTasksSection extends StatefulWidget {
  final VoidCallback onSeeAllPressed;

  const FocusTasksSection({
    super.key,
    required this.onSeeAllPressed,
  });

  @override
  State<FocusTasksSection> createState() => _FocusTasksSectionState();
}

class _FocusTasksSectionState extends State<FocusTasksSection> {
  // Data inisial sesuai prototipe HTML
  final List<FocusTaskData> _tasks = [
    FocusTaskData(
      id: '1',
      title: 'Beli Stok Susu & Popok',
      subtitle: 'Belanja Pulang Kerja',
      subtitleIcon: Icons.shopping_cart_outlined,
      isCompleted: false,
    ),
    FocusTaskData(
      id: '2',
      title: 'Bayar Tagihan Listrik',
      subtitle: 'Tenggat Hari Ini!',
      subtitleIcon: Icons.error_outline_rounded,
      subtitleColor: AppColors.accentTerracotta,
      isCompleted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Fokus Hari Ini',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            GestureDetector(
              onTap: widget.onSeeAllPressed,
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentTerracotta,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List Tugas
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return FocusTaskItem(
              title: task.title,
              subtitle: task.subtitle,
              subtitleIcon: task.subtitleIcon,
              subtitleColor: task.subtitleColor,
              isCompleted: task.isCompleted,
              onToggle: (val) {
                setState(() {
                  task.isCompleted = val ?? false;
                });
              },
            );
          },
        ),
      ],
    );
  }
}
