import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meal_plan_model.dart';

abstract class MealPlanRemoteDataSource {
  Stream<List<MealPlanModel>> watchFamilyMealPlans(String familyId);
  Future<List<MealPlanModel>> getMealPlansByDate({
    required String familyId,
    required DateTime date,
  });
  Future<MealPlanModel> createMealPlan(MealPlanModel mealPlan);
  Future<void> updateMealPlan(MealPlanModel mealPlan);
  Future<void> deleteMealPlan(String id);
  Future<String> uploadMealPhoto({
    required String mealId,
    required List<int> imageBytes,
    required String fileName,
  });
}

class MealPlanRemoteDataSourceImpl implements MealPlanRemoteDataSource {
  final SupabaseClient _client;

  MealPlanRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<MealPlanModel>> watchFamilyMealPlans(String familyId) {
    return _client
        .from('meal_plans')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('plan_date', ascending: true)
        .map((data) => data.map((json) => MealPlanModel.fromJson(json)).toList());
  }

  @override
  Future<List<MealPlanModel>> getMealPlansByDate({
    required String familyId,
    required DateTime date,
  }) async {
    final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final res = await _client
        .from('meal_plans')
        .select()
        .eq('family_id', familyId)
        .eq('plan_date', dateStr);

    return (res as List)
        .map((json) => MealPlanModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MealPlanModel> createMealPlan(MealPlanModel mealPlan) async {
    final data = mealPlan.toJson();
    final res = await _client.from('meal_plans').insert(data).select().single();
    return MealPlanModel.fromJson(res);
  }

  @override
  Future<void> updateMealPlan(MealPlanModel mealPlan) async {
    final data = mealPlan.toJson();
    await _client.from('meal_plans').update(data).eq('id', mealPlan.id);
  }

  @override
  Future<void> deleteMealPlan(String id) async {
    await _client.from('meal_plans').delete().eq('id', id);
  }

  @override
  Future<String> uploadMealPhoto({
    required String mealId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'meal_${mealId}_$cleanFileName';

    await _client.storage.from('meals').uploadBinary(
      path,
      imageBytes as dynamic,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );

    final publicUrl = _client.storage.from('meals').getPublicUrl(path);
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }
}
