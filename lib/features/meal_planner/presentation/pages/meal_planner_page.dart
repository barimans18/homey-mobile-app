import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/responsive/responsive_layout.dart';
import '../../../../core/presentation/widgets/custom_app_bar.dart';
import '../../../../core/services/session_storage_service.dart';
import '../../../auth/presentation/cubit/family_cubit.dart';
import '../../../auth/presentation/cubit/family_state.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../cubit/meal_plan_cubit.dart';
import '../cubit/meal_plan_state.dart';
import 'add_edit_meal_plan_page.dart';

/// Halaman Baru Data Lengkap Menu Makan Keluarga dengan Filter Kalender, Tambah, Edit, & Delete
class MealPlannerPage extends StatefulWidget {
  final DateTime? initialDate;

  const MealPlannerPage({super.key, this.initialDate});

  @override
  State<MealPlannerPage> createState() => _MealPlannerPageState();
}

class _MealPlannerPageState extends State<MealPlannerPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealPlanCubit>().selectDate(_selectedDate);
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
    context.read<MealPlanCubit>().selectDate(_selectedDate);
  }

  void _changeMonth(int offset) {
    final newYear =
        _selectedDate.year + ((_selectedDate.month + offset - 1) ~/ 12);
    final newMonth = ((_selectedDate.month + offset - 1) % 12) + 1;
    final maxDays = DateUtils.getDaysInMonth(newYear, newMonth);
    final newDay = _selectedDate.day.clamp(1, maxDays);
    _onDateSelected(DateTime(newYear, newMonth, newDay));
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  List<DateTime> _getWeekDaysForDate(DateTime anchor) {
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    return List.generate(7, (index) {
      final d = monday.add(Duration(days: index));
      return DateTime(d.year, d.month, d.day);
    });
  }

  void _confirmDelete(BuildContext context, MealPlanEntity meal) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
        title: const Text(
          'Hapus Menu Makan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text('Apakah Anda yakin ingin menghapus "${meal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<MealPlanCubit>().deleteMealPlan(meal.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menu makanan berhasil dihapus!'),
                  backgroundColor: AppColors.accentGreen,
                ),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddEdit(
    BuildContext context, {
    required String familyId,
    required String userId,
    MealPlanEntity? existingMeal,
    MealType? defaultMealType,
  }) {
    final cubit = context.read<MealPlanCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: AddEditMealPlanPage(
            familyId: familyId,
            userId: userId,
            initialDate: _selectedDate,
            existingMealPlan: existingMeal,
            initialMealType: defaultMealType,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String familyId =
        sl<SessionStorageService>().getFamilyId() ??
        '54e56ad4-eba8-4a1b-ae7c-a453d9ae3243';
    String currentUserId =
        sl<SessionStorageService>().getUserId() ??
        '6471baf6-3b32-4a9b-9ee2-6ada214e4eb2';

    try {
      final familyState = context.watch<FamilyCubit>().state;
      if (familyState is FamilyLoaded) {
        if (familyState.family != null) familyId = familyState.family!.id;
        currentUserId = familyState.profile.id;
      }
    } catch (_) {
      // Fallback jika FamilyCubit tidak tersedia di tree saat ini
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Menu Makan Keluarga',
        fontSize: 24,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentTerracotta,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Menu',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => _navigateToAddEdit(
          context,
          familyId: familyId,
          userId: currentUserId,
        ),
      ),
      body: SafeArea(
        child: ResponsiveContentContainer(
          padding: EdgeInsets.fromLTRB(
            context.isDesktop ? 32 : 24,
            8,
            context.isDesktop ? 32 : 24,
            context.isDesktop ? 32 : 90,
          ),
          child: SingleChildScrollView(
            child: ResponsiveLayout(
              // Mobile: 1 Kolom Vertikal
              mobile: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDynamicWeeklyCalendar(context),
                  const SizedBox(height: 20),
                  _buildDateHeader(),
                  const SizedBox(height: 16),
                  _buildMealSlots(familyId, currentUserId),
                ],
              ),
              // Desktop: 2 Kolom
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDynamicWeeklyCalendar(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateHeader(),
                        const SizedBox(height: 16),
                        _buildMealSlots(familyId, currentUserId),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return BlocBuilder<MealPlanCubit, MealPlanState>(
      builder: (context, state) {
        int totalMealsCount = 0;
        if (state is MealPlanLoaded) {
          totalMealsCount = state.todayMeals.length;
        }

        final dateStr = DateFormat(
          'EEEE, d MMMM yyyy',
          'id_ID',
        ).format(_selectedDate);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Jadwal Hidangan Pasutri',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentTerracotta.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalMealsCount Menu',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentTerracotta,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMealSlots(String familyId, String currentUserId) {
    return BlocBuilder<MealPlanCubit, MealPlanState>(
      builder: (context, state) {
        if (state is MealPlanLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(
                color: AppColors.accentTerracotta,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        MealPlanEntity? breakfast;
        MealPlanEntity? lunch;
        MealPlanEntity? dinner;

        if (state is MealPlanLoaded) {
          breakfast = state.getMeal(MealType.breakfast);
          lunch = state.getMeal(MealType.lunch);
          dinner = state.getMeal(MealType.dinner);
        }

        return Column(
          children: [
            _buildMealSlotCard(
              context,
              type: MealType.breakfast,
              meal: breakfast,
              familyId: familyId,
              userId: currentUserId,
            ),
            const SizedBox(height: 16),
            _buildMealSlotCard(
              context,
              type: MealType.lunch,
              meal: lunch,
              familyId: familyId,
              userId: currentUserId,
            ),
            const SizedBox(height: 16),
            _buildMealSlotCard(
              context,
              type: MealType.dinner,
              meal: dinner,
              familyId: familyId,
              userId: currentUserId,
            ),
          ],
        );
      },
    );
  }

  // 1. Kalender Mingguan Dinamis dengan Navigasi / Filter Bulan (Sama dengan Agenda)
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
              // Filter / Pemilih Bulan (Klik untuk buka Date Picker)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _pickMonth(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
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
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      color: AppColors.textPrimary,
                      tooltip: 'Bulan Sebelumnya',
                      onPressed: () => _changeMonth(-1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
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
              final isSelected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              final isToday =
                  date.year == today.year &&
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
                            : (isToday
                                  ? AppColors.accentGreen
                                  : AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentTerracotta
                            : (isToday
                                  ? AppColors.accentGreen.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.transparent),
                        shape: BoxShape.circle,
                        boxShadow: isSelected ? AppShadows.soft : null,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: AppColors.accentGreen,
                                width: 1.5,
                              )
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
                              : (isToday
                                    ? AppColors.accentGreen
                                    : AppColors.textPrimary),
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

  // 2. Widget Slot Menu Makan (Sarapan, Makan Siang, Makan Malam)
  Widget _buildMealSlotCard(
    BuildContext context, {
    required MealType type,
    required MealPlanEntity? meal,
    required String familyId,
    required String userId,
  }) {
    if (meal == null) {
      // Slot Kosong dengan ajakan tambah
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getMealIcon(type),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Belum ada menu yang ditentukan',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTerracotta.withValues(
                  alpha: 0.12,
                ),
                foregroundColor: AppColors.accentTerracotta,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Tentukan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              onPressed: () => _navigateToAddEdit(
                context,
                familyId: familyId,
                userId: userId,
                defaultMealType: type,
              ),
            ),
          ],
        ),
      );
    }

    // Slot Berisi Menu Lengkap
    final hasImage = meal.imageUrl != null && meal.imageUrl!.isNotEmpty;
    final checkedIngredients = meal.ingredients
        .where((i) => i.isChecked)
        .length;
    final totalIngredients = meal.ingredients.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Badge Waktu Makan & Tombol Aksi (Edit, Delete)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentTerracotta.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getMealIcon(type),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentTerracotta,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    // Tombol Edit
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      tooltip: 'Edit Menu',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => _navigateToAddEdit(
                        context,
                        familyId: familyId,
                        userId: userId,
                        existingMeal: meal,
                        defaultMealType: type,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Tombol Hapus
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      tooltip: 'Hapus Menu',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => _confirmDelete(context, meal),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Foto Masakan (jika ada)
          if (hasImage) ...[
            ClipRRect(
              child: Image.network(
                meal.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],

          // Informasi Makanan & Bahan
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meal.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (totalIngredients > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '$checkedIngredients/$totalIngredients bahan siap',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          size: 16,
                          color: AppColors.accentTerracotta,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            meal.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Daftar Bahan-Bahan Masakan (Interactive Checklist)
                if (meal.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Bahan Masakan (Centang jika siap):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: List.generate(meal.ingredients.length, (idx) {
                        final ing = meal.ingredients[idx];
                        return InkWell(
                          onTap: () {
                            context.read<MealPlanCubit>().toggleIngredientCheck(
                              mealId: meal.id,
                              ingredientIndex: idx,
                              isChecked: !ing.isChecked,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: ing.isChecked,
                                    activeColor: AppColors.accentGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      context
                                          .read<MealPlanCubit>()
                                          .toggleIngredientCheck(
                                            mealId: meal.id,
                                            ingredientIndex: idx,
                                            isChecked: val ?? false,
                                          );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ing.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: ing.isChecked
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary,
                                      decoration: ing.isChecked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return '🍳';
      case MealType.lunch:
        return '🍛';
      case MealType.dinner:
        return '🍲';
    }
  }
}
