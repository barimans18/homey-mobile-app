import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../cubit/meal_plan_cubit.dart';
import '../cubit/meal_plan_state.dart';
import 'add_meal_plan_bottom_sheet.dart';

class MealPlanDetailBottomSheet extends StatelessWidget {
  final MealPlanEntity mealPlan;
  final String familyId;
  final String userId;

  const MealPlanDetailBottomSheet({
    super.key,
    required this.mealPlan,
    required this.familyId,
    required this.userId,
  });

  static Future<void> show(
    BuildContext context, {
    required MealPlanEntity mealPlan,
    required String familyId,
    required String userId,
  }) {
    final cubit = context.read<MealPlanCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: MealPlanDetailBottomSheet(
          mealPlan: mealPlan,
          familyId: familyId,
          userId: userId,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
        title: const Text('Hapus Menu Makan', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Apakah Anda yakin ingin menghapus "${mealPlan.title}"?'),
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
              Navigator.pop(context); // Close detail sheet
              context.read<MealPlanCubit>().deleteMealPlan(mealPlan.id);
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

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(mealPlan.planDate);

    return BlocBuilder<MealPlanCubit, MealPlanState>(
      builder: (context, state) {
        // Find current live state of this meal if updated
        MealPlanEntity currentMeal = mealPlan;
        if (state is MealPlanLoaded) {
          final found = state.mealPlans.where((m) => m.id == mealPlan.id);
          if (found.isNotEmpty) {
            currentMeal = found.first;
          }
        }

        final checkedCount = currentMeal.ingredients.where((i) => i.isChecked).length;
        final totalCount = currentMeal.ingredients.length;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.bottomSheetRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Badge & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentTerracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentMeal.mealType.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentTerracotta,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.accentTerracotta),
                        tooltip: 'Edit Menu',
                        onPressed: () {
                          Navigator.pop(context);
                          AddMealPlanBottomSheet.show(
                            context,
                            familyId: familyId,
                            userId: userId,
                            initialDate: currentMeal.planDate,
                            existingMealPlan: currentMeal,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        tooltip: 'Hapus Menu',
                        onPressed: () => _confirmDelete(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo if available
                      if (currentMeal.imageUrl != null && currentMeal.imageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: AppRadii.cardRadius,
                          child: Image.network(
                            currentMeal.imageUrl!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 140,
                              color: AppColors.background,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_rounded, size: 40, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        currentMeal.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Catatan / Resep (Free Text)
                      if (currentMeal.notes != null && currentMeal.notes!.isNotEmpty) ...[
                        const Text(
                          'Catatan & Resep Masakan 📝',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            currentMeal.notes!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Bahan-bahan Masakan (Multi Checkbox)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bahan-Bahan Makanan 🛒',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (totalCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: checkedCount == totalCount
                                    ? AppColors.accentGreen.withValues(alpha: 0.15)
                                    : AppColors.accentTerracotta.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$checkedCount / $totalCount Siap',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: checkedCount == totalCount
                                      ? AppColors.accentGreen
                                      : AppColors.accentTerracotta,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (currentMeal.ingredients.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Belum ada daftar bahan yang dicatat.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentMeal.ingredients.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final item = currentMeal.ingredients[index];
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                context.read<MealPlanCubit>().toggleIngredientCheck(
                                      mealId: currentMeal.id,
                                      ingredientIndex: index,
                                      isChecked: !item.isChecked,
                                    );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: item.isChecked
                                      ? AppColors.background
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: item.isChecked
                                        ? AppColors.accentGreen.withValues(alpha: 0.4)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.isChecked
                                          ? Icons.check_box_rounded
                                          : Icons.check_box_outline_blank_rounded,
                                      color: item.isChecked
                                          ? AppColors.accentGreen
                                          : AppColors.textMuted,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: item.isChecked
                                              ? AppColors.textMuted
                                              : AppColors.textPrimary,
                                          decoration: item.isChecked
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              PrimaryButton(
                text: 'Tutup Detail',
                icon: Icons.check_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
