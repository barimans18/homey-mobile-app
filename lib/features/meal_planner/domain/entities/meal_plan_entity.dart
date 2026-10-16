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

class MealPlanEntity extends Equatable {
  final String id;
  final String familyId;
  final String createdBy;
  final DateTime planDate;
  final MealType mealType;
  final String title;
  final String? notes;
  final List<String> ingredients;
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
    this.isSyncedToGrocery = false,
  });

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
        isSyncedToGrocery,
      ];
}
