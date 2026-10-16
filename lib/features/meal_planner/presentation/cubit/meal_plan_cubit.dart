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
    try {
      await _repository.createMealPlan(mealPlan);
    } catch (e) {
      emit(MealPlanError('Gagal menambahkan menu makan: $e'));
    }
  }

  Future<void> deleteMealPlan(String id) async {
    try {
      await _repository.deleteMealPlan(id);
    } catch (e) {
      emit(MealPlanError('Gagal menghapus menu makan: $e'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
