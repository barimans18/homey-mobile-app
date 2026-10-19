import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import 'meal_plan_state.dart';

class MealPlanCubit extends Cubit<MealPlanState> {
  final MealPlanRepository _repository;
  StreamSubscription<List<MealPlanEntity>>? _subscription;

  MealPlanCubit({required MealPlanRepository repository})
      : _repository = repository,
        super(const MealPlanInitial());

  void watchFamilyMealPlans(String familyId, {DateTime? initialDate}) {
    emit(const MealPlanLoading());
    _subscription?.cancel();

    final date = initialDate ?? DateTime.now();

    _subscription = _repository.watchFamilyMealPlans(familyId).listen(
      (meals) {
        final currentDate = state is MealPlanLoaded
            ? (state as MealPlanLoaded).selectedDate
            : date;
        emit(MealPlanLoaded(mealPlans: meals, selectedDate: currentDate));
      },
      onError: (e) {
        emit(MealPlanError('Gagal menyinkronkan menu makan: $e'));
      },
    );
  }

  void selectDate(DateTime date) {
    if (state is MealPlanLoaded) {
      emit((state as MealPlanLoaded).copyWith(selectedDate: date));
    } else {
      emit(MealPlanLoaded(mealPlans: const [], selectedDate: date));
    }
  }

  Future<void> addMealPlan(MealPlanEntity mealPlan) async {
    final currentState = state;
    if (currentState is MealPlanLoaded) {
      final updatedList = [mealPlan, ...currentState.mealPlans];
      emit(currentState.copyWith(mealPlans: updatedList));
    }
    try {
      await _repository.createMealPlan(mealPlan);
    } catch (e) {
      emit(currentState);
      emit(MealPlanError('Gagal menambahkan menu makan: $e'));
    }
  }

  Future<void> updateMealPlan(MealPlanEntity mealPlan) async {
    final currentState = state;
    if (currentState is MealPlanLoaded) {
      final updatedList = currentState.mealPlans.map((m) {
        return m.id == mealPlan.id ? mealPlan : m;
      }).toList();
      emit(currentState.copyWith(mealPlans: updatedList));
    }
    try {
      await _repository.updateMealPlan(mealPlan);
    } catch (e) {
      emit(currentState);
      emit(MealPlanError('Gagal memperbarui menu makan: $e'));
    }
  }

  Future<void> toggleIngredientCheck({
    required String mealId,
    required int ingredientIndex,
    required bool isChecked,
  }) async {
    final currentState = state;
    if (currentState is! MealPlanLoaded) return;

    final targetMeal = currentState.mealPlans.firstWhere(
      (m) => m.id == mealId,
      orElse: () => throw Exception('Meal not found'),
    );

    if (ingredientIndex < 0 || ingredientIndex >= targetMeal.ingredients.length) {
      return;
    }

    final updatedIngredients = List<MealIngredient>.from(targetMeal.ingredients);
    updatedIngredients[ingredientIndex] = updatedIngredients[ingredientIndex].copyWith(
      isChecked: isChecked,
    );

    final updatedMeal = targetMeal.copyWith(ingredients: updatedIngredients);
    await updateMealPlan(updatedMeal);
  }

  Future<String> uploadMealPhoto({
    required String mealId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    return _repository.uploadMealPhoto(
      mealId: mealId,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }

  Future<void> deleteMealPlan(String id) async {
    final currentState = state;
    if (currentState is MealPlanLoaded) {
      final updatedList =
          currentState.mealPlans.where((m) => m.id != id).toList();
      emit(currentState.copyWith(mealPlans: updatedList));
    }
    try {
      await _repository.deleteMealPlan(id);
    } catch (e) {
      emit(currentState);
      emit(MealPlanError('Gagal menghapus menu makan: $e'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
