import 'package:equatable/equatable.dart';

/// Entity Tugas / Agenda dalam keluarga
class TaskEntity extends Equatable {
  final String id;
  final String familyId;
  final String createdBy;
  final String title;
  final String? description;
  final String assignee; // 'suami', 'istri', atau 'both'
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;
  final DateTime createdAt;

  const TaskEntity({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.title,
    this.description,
    required this.assignee,
    this.dueDate,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
    required this.createdAt,
  });

  TaskEntity copyWith({
    String? id,
    String? familyId,
    String? createdBy,
    String? title,
    String? description,
    String? assignee,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
    DateTime? createdAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        createdBy,
        title,
        description,
        assignee,
        dueDate,
        isCompleted,
        completedAt,
        completedBy,
        createdAt,
      ];
}
