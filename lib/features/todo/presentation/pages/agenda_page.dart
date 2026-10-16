import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/presentation/widgets/custom_app_bar.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';

/// Halaman Agenda & Shared To-Do List yang terhubung Realtime dengan Supabase
class AgendaPage extends StatelessWidget {
  final String familyId;
  final String currentUserId;

  const AgendaPage({
    super.key,
    this.familyId = '00000000-0000-0000-0000-000000000000',
    this.currentUserId = 'dummy-user-id',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Agenda & Rencana 🗓️',
        subtitle: 'Sinkronisasi real-time Suami & Istri',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.accentTerracotta,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Weekly Calendar Strip
              _buildWeeklyCalendarStrip(context),
              const SizedBox(height: 24),

              // 2. Meal Planner Widget (Hari Ini)
              _buildMealPlannerPreview(context),
              const SizedBox(height: 24),

              // 3. Shared To-Do List dengan Realtime Sync
              Text(
                'Daftar Tugas Bersama',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),

              BlocConsumer<TaskCubit, TaskState>(
                listener: (context, state) {
                  if (state is TaskError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is TaskLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTerracotta),
                        ),
                      ),
                    );
                  }

                  if (state is TaskLoaded) {
                    if (state.tasks.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.tasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = state.tasks[index];
                        return _buildTaskCard(context, task);
                      },
                    );
                  }

                  // Default Fallback
                  return _buildEmptyState(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyCalendarStrip(BuildContext context) {
    final days = [
      {'day': 'Sen', 'date': '12', 'active': false},
      {'day': 'Sel', 'date': '13', 'active': false},
      {'day': 'Rab', 'date': '14', 'active': false},
      {'day': 'Kam', 'date': '15', 'active': false},
      {'day': 'Jum', 'date': '16', 'active': true},
      {'day': 'Sab', 'date': '17', 'active': false},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardRadius,
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((item) {
          final isActive = item['active'] as bool;
          return Column(
            children: [
              Text(
                item['day'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.accentTerracotta : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accentTerracotta : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isActive ? AppShadows.soft : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  item['date'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealPlannerPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentTerracotta.withValues(alpha: 0.08),
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.accentTerracotta.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant_rounded, color: AppColors.accentTerracotta, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MAKAN MALAM HARI INI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentTerracotta,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ayam Teriyaki & Cah Brokoli',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskEntity task) {
    final isHusband = task.assignee == 'suami';
    final accentColor = isHusband ? AppColors.accentTerracotta : AppColors.accentGreen;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.cardRadius,
        child: Stack(
          children: [
            // Left Accent Strip
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                color: accentColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox Interaktif yang memicu Cubit
                  InkWell(
                    onTap: () {
                      context.read<TaskCubit>().toggleTask(
                            taskId: task.id,
                            isCompleted: !task.isCompleted,
                            currentUserId: currentUserId,
                          );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: task.isCompleted ? AppColors.accentTerracotta : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accentTerracotta,
                          width: 2,
                        ),
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Informasi Tugas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: task.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  task.dueDate != null ? '19:00' : 'Hari Ini',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            // Assignee Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 7,
                                    backgroundColor: accentColor,
                                    child: Text(
                                      isHusband ? 'S' : 'I',
                                      style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isHusband ? 'Suami' : 'Istri',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.checklist_rounded, size: 48, color: AppColors.accentGreen.withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          const Text(
            'Belum ada tugas hari ini 🎉',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gunakan tombol (+) di tengah untuk menambahkan agenda keluarga.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
