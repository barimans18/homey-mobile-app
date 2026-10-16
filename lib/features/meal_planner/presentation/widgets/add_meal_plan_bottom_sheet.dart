import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../cubit/meal_plan_cubit.dart';

class AddMealPlanBottomSheet extends StatefulWidget {
  final String familyId;
  final String userId;
  final DateTime initialDate;

  const AddMealPlanBottomSheet({
    super.key,
    required this.familyId,
    required this.userId,
    required this.initialDate,
  });

  static Future<void> show(
    BuildContext context, {
    required String familyId,
    required String userId,
    required DateTime initialDate,
  }) {
    final cubit = context.read<MealPlanCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: AddMealPlanBottomSheet(
          familyId: familyId,
          userId: userId,
          initialDate: initialDate,
        ),
      ),
    );
  }

  @override
  State<AddMealPlanBottomSheet> createState() => _AddMealPlanBottomSheetState();
}

class _AddMealPlanBottomSheetState extends State<AddMealPlanBottomSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  MealType _selectedType = MealType.dinner;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan nama menu makanan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final mealPlan = MealPlanEntity(
      id: const Uuid().v4(),
      familyId: widget.familyId,
      createdBy: widget.userId,
      planDate: _selectedDate,
      mealType: _selectedType,
      title: title,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await context.read<MealPlanCubit>().addMealPlan(mealPlan);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Menu ${_selectedType.label} berhasil disimpan! 🍽️'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate);

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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rencana Menu Makan 🍽️',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Rencanakan menu lezat untuk $dateStr',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Pilihan Waktu Makan (Sarapan, Siang, Malam)
            const Text(
              'Waktu Makan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: MealType.values.map((type) {
                final isSelected = _selectedType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentTerracotta : AppColors.surface,
                        borderRadius: AppRadii.chipRadius,
                        border: Border.all(
                          color: isSelected ? AppColors.accentTerracotta : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Nama Menu
            const Text(
              'Nama Menu / Masakan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Misal: Ayam Bakar Madu & Sambal Bajak',
                prefixIcon: Icon(Icons.restaurant_rounded, color: AppColors.accentTerracotta),
              ),
            ),
            const SizedBox(height: 16),

            // Catatan / Bahan Masak
            const Text(
              'Catatan & Bahan Makanan (Opsional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Misal: Beli ayam 1 ekor, madu, kecap manis, timun',
                prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppColors.accentGreen),
              ),
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              text: 'Simpan Rencana Menu 🍲',
              isLoading: _isLoading,
              icon: Icons.check_circle_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
