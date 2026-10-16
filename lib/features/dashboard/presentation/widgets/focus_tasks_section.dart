import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/session_storage_service.dart';
import '../../../todo/domain/entities/task_entity.dart';
import '../../../todo/presentation/cubit/task_cubit.dart';
import '../../../todo/presentation/cubit/task_state.dart';
import 'focus_task_item.dart';

/// Bagian "Fokus Hari Ini" di Tab Beranda yang tersinkronisasi live dengan Supabase
class FocusTasksSection extends StatelessWidget {
  final VoidCallback onSeeAllPressed;

  const FocusTasksSection({
    super.key,
    required this.onSeeAllPressed,
  });

  IconData _getAssigneeIcon(String assignee) {
    switch (assignee) {
      case 'suami':
        return Icons.person_rounded;
      case 'istri':
        return Icons.face_3_rounded;
      default:
        return Icons.people_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = sl<SessionStorageService>().getUserId() ?? '6471baf6-3b32-4a9b-9ee2-6ada214e4eb2';

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
              onTap: onSeeAllPressed,
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

        // List Tugas Live dari Supabase
        BlocBuilder<TaskCubit, TaskState>(
          builder: (context, state) {
            if (state is TaskLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.accentTerracotta,
                  ),
                ),
              );
            }

            if (state is TaskError) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadii.cardRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  state.message,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              );
            }

            List<TaskEntity> tasks = [];
            if (state is TaskLoaded) {
              tasks = state.tasks;
            }

            if (tasks.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadii.cardRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.done_all_rounded, color: AppColors.accentGreen, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Semua Tugas Selesai! 🎉',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tidak ada agenda tertunda untuk hari ini.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Prioritaskan tugas belum selesai, ambil maksimal 3
            final sortedTasks = List<TaskEntity>.from(tasks)
              ..sort((a, b) {
                if (a.isCompleted == b.isCompleted) return 0;
                return a.isCompleted ? 1 : -1;
              });

            final focusTasks = sortedTasks.take(3).toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: focusTasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final task = focusTasks[index];
                final subtitle = (task.description != null && task.description!.isNotEmpty)
                    ? task.description!
                    : 'Tugas untuk ${task.assignee.toUpperCase()}';

                return FocusTaskItem(
                  title: task.title,
                  subtitle: subtitle,
                  subtitleIcon: _getAssigneeIcon(task.assignee),
                  subtitleColor: task.isCompleted ? AppColors.textMuted : AppColors.accentTerracotta,
                  isCompleted: task.isCompleted,
                  onToggle: (val) {
                    context.read<TaskCubit>().toggleTask(
                          taskId: task.id,
                          isCompleted: val ?? !task.isCompleted,
                          currentUserId: currentUserId,
                        );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
