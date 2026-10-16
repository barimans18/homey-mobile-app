import '../entities/meal_plan_entity.dart';

abstract class MealPlanRepository {
  Stream<List<MealPlanEntity>> watchFamilyMealPlans(String familyId);
  Future<List<MealPlanEntity>> getMealPlansByDate({
    required String familyId,
    required DateTime date,
  });
  Future<MealPlanEntity> createMealPlan(MealPlanEntity mealPlan);
  Future<void> deleteMealPlan(String id);
}
