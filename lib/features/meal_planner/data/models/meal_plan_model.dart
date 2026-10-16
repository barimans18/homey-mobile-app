import '../../domain/entities/meal_plan_entity.dart';

class MealPlanModel extends MealPlanEntity {
  const MealPlanModel({
    required super.id,
    required super.familyId,
    required super.createdBy,
    required super.planDate,
    required super.mealType,
    required super.title,
    super.notes,
    super.ingredients,
    super.isSyncedToGrocery,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedIngredients = [];
    if (json['ingredients'] != null && json['ingredients'] is List) {
      parsedIngredients = (json['ingredients'] as List)
          .map((e) => e.toString())
          .toList();
    }

    DateTime parsedDate;
    if (json['plan_date'] is String) {
      parsedDate = DateTime.parse(json['plan_date'] as String);
    } else {
      parsedDate = DateTime.now();
    }

    return MealPlanModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      createdBy: json['created_by'] as String? ?? '',
      planDate: parsedDate,
      mealType: MealType.fromString(json['meal_type'] as String? ?? 'malam'),
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String?,
      ingredients: parsedIngredients,
      isSyncedToGrocery: json['is_synced_to_grocery'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'created_by': createdBy,
      'plan_date': "${planDate.year.toString().padLeft(4, '0')}-${planDate.month.toString().padLeft(2, '0')}-${planDate.day.toString().padLeft(2, '0')}",
      'meal_type': mealType.value,
      'title': title,
      'notes': notes,
      'ingredients': ingredients,
      'is_synced_to_grocery': isSyncedToGrocery,
    };
  }
}
