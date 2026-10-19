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
    super.imageUrl,
    super.isSyncedToGrocery,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    List<MealIngredient> parsedIngredients = [];
    if (json['ingredients'] != null && json['ingredients'] is List) {
      parsedIngredients = (json['ingredients'] as List)
          .map((e) => MealIngredient.fromDynamic(e))
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
      imageUrl: json['image_url'] as String?,
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
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      if (imageUrl != null) 'image_url': imageUrl,
      'is_synced_to_grocery': isSyncedToGrocery,
    };
  }
}
