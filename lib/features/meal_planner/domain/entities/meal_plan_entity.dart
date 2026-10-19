import 'package:equatable/equatable.dart';

enum MealType {
  breakfast('sarapan', 'Sarapan 🍳'),
  lunch('siang', 'Makan Siang 🍛'),
  dinner('malam', 'Makan Malam 🍲');

  final String value;
  final String label;
  const MealType(this.value, this.label);

  static MealType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'sarapan':
        return MealType.breakfast;
      case 'siang':
        return MealType.lunch;
      case 'malam':
      default:
        return MealType.dinner;
    }
  }
}

class MealIngredient extends Equatable {
  final String name;
  final bool isChecked;

  const MealIngredient({
    required this.name,
    this.isChecked = false,
  });

  MealIngredient copyWith({String? name, bool? isChecked}) {
    return MealIngredient(
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  factory MealIngredient.fromDynamic(dynamic json) {
    if (json is Map) {
      return MealIngredient(
        name: json['name'] as String? ?? '',
        isChecked: json['is_checked'] as bool? ?? false,
      );
    } else if (json is String) {
      return MealIngredient(name: json, isChecked: false);
    }
    return MealIngredient(name: json.toString(), isChecked: false);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'is_checked': isChecked,
    };
  }

  @override
  List<Object?> get props => [name, isChecked];
}

class MealPlanEntity extends Equatable {
  final String id;
  final String familyId;
  final String createdBy;
  final DateTime planDate;
  final MealType mealType;
  final String title;
  final String? notes;
  final List<MealIngredient> ingredients;
  final String? imageUrl;
  final bool isSyncedToGrocery;

  const MealPlanEntity({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.planDate,
    required this.mealType,
    required this.title,
    this.notes,
    this.ingredients = const [],
    this.imageUrl,
    this.isSyncedToGrocery = false,
  });

  MealPlanEntity copyWith({
    String? id,
    String? familyId,
    String? createdBy,
    DateTime? planDate,
    MealType? mealType,
    String? title,
    String? notes,
    List<MealIngredient>? ingredients,
    String? imageUrl,
    bool? isSyncedToGrocery,
  }) {
    return MealPlanEntity(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      planDate: planDate ?? this.planDate,
      mealType: mealType ?? this.mealType,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      ingredients: ingredients ?? this.ingredients,
      imageUrl: imageUrl ?? this.imageUrl,
      isSyncedToGrocery: isSyncedToGrocery ?? this.isSyncedToGrocery,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        createdBy,
        planDate,
        mealType,
        title,
        notes,
        ingredients,
        imageUrl,
        isSyncedToGrocery,
      ];
}
