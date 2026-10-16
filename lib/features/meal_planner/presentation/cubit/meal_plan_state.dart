import 'package:equatable/equatable.dart';
import '../../domain/entities/meal_plan_entity.dart';

abstract class MealPlanState extends Equatable {
  const MealPlanState();

  @override
  List<Object?> get props => [];
}

class MealPlanInitial extends MealPlanState {
  const MealPlanInitial();
}

class MealPlanLoading extends MealPlanState {
  const MealPlanLoading();
}

class MealPlanLoaded extends MealPlanState {
  final List<MealPlanEntity> mealPlans;
  final DateTime selectedDate;

  const MealPlanLoaded({
    required this.mealPlans,
    required this.selectedDate,
  });

  /// Ambil menu untuk tipe makanan tertentu pada tanggal aktif
  MealPlanEntity? getMeal(MealType type) {
    try {
      return mealPlans.firstWhere(
        (m) =>
            m.mealType == type &&
            m.planDate.year == selectedDate.year &&
            m.planDate.month == selectedDate.month &&
            m.planDate.day == selectedDate.day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Ambil semua menu makan untuk tanggal aktif
  List<MealPlanEntity> get todayMeals {
    return mealPlans
        .where((m) =>
            m.planDate.year == selectedDate.year &&
            m.planDate.month == selectedDate.month &&
            m.planDate.day == selectedDate.day)
        .toList();
  }

  MealPlanLoaded copyWith({
    List<MealPlanEntity>? mealPlans,
    DateTime? selectedDate,
  }) {
    return MealPlanLoaded(
      mealPlans: mealPlans ?? this.mealPlans,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  @override
  List<Object?> get props => [mealPlans, selectedDate];
}

class MealPlanError extends MealPlanState {
  final String message;

  const MealPlanError(this.message);

  @override
  List<Object?> get props => [message];
}
