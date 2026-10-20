import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/custom_app_bar.dart';
import '../../../../core/services/session_storage_service.dart';
import '../../../auth/presentation/cubit/family_cubit.dart';
import '../../../auth/presentation/cubit/family_state.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../widgets/add_task_bottom_sheet.dart';

/// Halaman Agenda, Kalender Mingguan & Shared Tasks live Supabase
class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  late DateTime _selectedDate;
  String _taskFilter = 'all'; // 'all', 'today', 'suami', 'istri'

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
  }

  void _changeMonth(int offset) {
    final newYear = _selectedDate.year + ((_selectedDate.month + offset - 1) ~/ 12);
    final newMonth = ((_selectedDate.month + offset - 1) % 12) + 1;
    final maxDays = DateUtils.getDaysInMonth(newYear, newMonth);
    final newDay = _selectedDate.day.clamp(1, maxDays);
    _onDateSelected(DateTime(newYear, newMonth, newDay));
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'PILIH BULAN & TANGGAL',
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
      _onDateSelected(picked);
    }
  }

  /// Ambil 7 hari dalam minggu berdasarkan tanggal yang dipilih
  List<DateTime> _getWeekDaysForDate(DateTime anchor) {
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    return List.generate(7, (index) {
      final d = monday.add(Duration(days: index));
      return DateTime(d.year, d.month, d.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    String familyId = sl<SessionStorageService>().getFamilyId() ?? '54e56ad4-eba8-4a1b-ae7c-a453d9ae3243';
    String currentUserId = sl<SessionStorageService>().getUserId() ?? '6471baf6-3b32-4a9b-9ee2-6ada214e4eb2';

    final familyState = context.watch<FamilyCubit>().state;
    if (familyState is FamilyLoaded) {
      if (familyState.family != null) familyId = familyState.family!.id;
      currentUserId = familyState.profile.id;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Agenda & Rencana 🗓️',
        subtitle: 'Sinkronisasi real-time Suami & Istri',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Kalender Mingguan Dinamis dengan Filter Bulan
              _buildDynamicWeeklyCalendar(context),
              const SizedBox(height: 24),

              // 2. Header & Filter Daftar Tugas Bersama
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Tugas Bersama',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentTerracotta,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                    label: const Text(
                      'Tugas Baru',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    onPressed: () {
                      AddTaskBottomSheet.show(
                        context,
                        familyId: familyId,
                        userId: currentUserId,
                        initialDueDate: _selectedDate,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Semua', 'all'),
                    _buildFilterChip('Hari Terpilih', 'selected_day'),
                    _buildFilterChip('Suami 👨', 'suami'),
                    _buildFilterChip('Istri 👩', 'istri'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Live Stream Tasks dari Supabase (TaskCubit)
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
                    final filteredTasks = _filterTasks(state.tasks);

                    if (filteredTasks.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return _buildTaskCard(context, task, currentUserId: currentUserId);
                      },
                    );
                  }

                  return _buildEmptyState(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TaskEntity> _filterTasks(List<TaskEntity> tasks) {
    switch (_taskFilter) {
      case 'selected_day':
        return tasks.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.year == _selectedDate.year &&
              t.dueDate!.month == _selectedDate.month &&
              t.dueDate!.day == _selectedDate.day;
        }).toList();
      case 'suami':
        return tasks.where((t) => t.assignee == 'suami' || t.assignee == 'both').toList();
      case 'istri':
        return tasks.where((t) => t.assignee == 'istri' || t.assignee == 'both').toList();
      case 'all':
      default:
        return tasks;
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _taskFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _taskFilter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentTerracotta : Colors.white,
          borderRadius: AppRadii.chipRadius,
          border: Border.all(
            color: isSelected ? AppColors.accentTerracotta : AppColors.border,
          ),
          boxShadow: isSelected ? AppShadows.soft : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // 1. Kalender Mingguan Dinamis dengan Navigasi / Filter Bulan
  Widget _buildDynamicWeeklyCalendar(BuildContext context) {
    final weekDays = _getWeekDaysForDate(_selectedDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardRadius,
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Filter / Pemilih Bulan (Klik untuk buka Date/Month Picker)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _pickMonth(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.accentTerracotta,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Tombol Navigasi Bulan (Prev / Next Month)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      color: AppColors.textPrimary,
                      tooltip: 'Bulan Sebelumnya',
                      onPressed: () => _changeMonth(-1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      color: AppColors.textPrimary,
                      tooltip: 'Bulan Selanjutnya',
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
              if (_selectedDate != today) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _onDateSelected(today),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Hari Ini',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays.map((date) {
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              final dayLabel = dayNames[date.weekday - 1];

              return GestureDetector(
                onTap: () => _onDateSelected(date),
                child: Column(
                  children: [
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.accentTerracotta
                            : (isToday ? AppColors.accentGreen : AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentTerracotta
                            : (isToday ? AppColors.accentGreen.withValues(alpha: 0.15) : Colors.transparent),
                        shape: BoxShape.circle,
                        boxShadow: isSelected ? AppShadows.soft : null,
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.accentGreen, width: 1.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? AppColors.accentGreen : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 2. Task Card dengan Checkbox Realtime & Delete
  Widget _buildTaskCard(
    BuildContext context,
    TaskEntity task, {
    required String currentUserId,
  }) {
    final isHusband = task.assignee == 'suami';
    final isBoth = task.assignee == 'both';
    final accentColor = isBoth
        ? AppColors.accentYellow
        : (isHusband ? AppColors.accentTerracotta : AppColors.accentGreen);

    String assigneeText = 'Keduanya';
    if (isHusband) assigneeText = 'Suami';
    if (task.assignee == 'istri') assigneeText = 'Istri';

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
                    borderRadius: BorderRadius.circular(8),
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
                        if (task.description != null && task.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            task.description!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  task.dueDate != null
                                      ? DateFormat('d MMM', 'id_ID').format(task.dueDate!)
                                      : 'Hari Ini',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            // Assignee Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 7,
                                    backgroundColor: accentColor,
                                    child: Text(
                                      isBoth ? 'K' : (isHusband ? 'S' : 'I'),
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    assigneeText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Hapus
                  GestureDetector(
                    onTap: () => _confirmDeleteTask(context, task.id),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
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

  void _confirmDeleteTask(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
        title: const Text('Hapus Tugas?'),
        content: const Text('Tugas ini akan dihapus dari daftar agenda bersama pasangan.'),
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
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<TaskCubit>().deleteTask(taskId);
            },
            child: const Text('Hapus'),
          ),
        ],
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
            'Tidak ada tugas pada filter ini 🎉',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gunakan tombol "Tugas Baru" di atas untuk menambah agenda bersama.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
