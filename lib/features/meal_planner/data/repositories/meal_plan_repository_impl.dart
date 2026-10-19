import '../../domain/entities/meal_plan_entity.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import '../datasources/meal_plan_remote_data_source.dart';
import '../models/meal_plan_model.dart';

class MealPlanRepositoryImpl implements MealPlanRepository {
  final MealPlanRemoteDataSource _remoteDataSource;

  MealPlanRepositoryImpl({required MealPlanRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<MealPlanEntity>> watchFamilyMealPlans(String familyId) {
    return _remoteDataSource.watchFamilyMealPlans(familyId);
  }

  @override
  Future<List<MealPlanEntity>> getMealPlansByDate({
    required String familyId,
    required DateTime date,
  }) {
    return _remoteDataSource.getMealPlansByDate(familyId: familyId, date: date);
  }

  @override
  Future<MealPlanEntity> createMealPlan(MealPlanEntity mealPlan) {
    final model = MealPlanModel(
      id: mealPlan.id,
      familyId: mealPlan.familyId,
      createdBy: mealPlan.createdBy,
      planDate: mealPlan.planDate,
      mealType: mealPlan.mealType,
      title: mealPlan.title,
      notes: mealPlan.notes,
      ingredients: mealPlan.ingredients,
      imageUrl: mealPlan.imageUrl,
      isSyncedToGrocery: mealPlan.isSyncedToGrocery,
    );
    return _remoteDataSource.createMealPlan(model);
  }

  @override
  Future<void> updateMealPlan(MealPlanEntity mealPlan) {
    final model = MealPlanModel(
      id: mealPlan.id,
      familyId: mealPlan.familyId,
      createdBy: mealPlan.createdBy,
      planDate: mealPlan.planDate,
      mealType: mealPlan.mealType,
      title: mealPlan.title,
      notes: mealPlan.notes,
      ingredients: mealPlan.ingredients,
      imageUrl: mealPlan.imageUrl,
      isSyncedToGrocery: mealPlan.isSyncedToGrocery,
    );
    return _remoteDataSource.updateMealPlan(model);
  }

  @override
  Future<void> deleteMealPlan(String id) {
    return _remoteDataSource.deleteMealPlan(id);
  }

  @override
  Future<String> uploadMealPhoto({
    required String mealId,
    required List<int> imageBytes,
    required String fileName,
  }) {
    return _remoteDataSource.uploadMealPhoto(
      mealId: mealId,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }
}
