import '../../domain/entities/task_entity.dart';

/// Data Model untuk tabel `tasks` di Supabase
class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.familyId,
    required super.createdBy,
    required super.title,
    super.description,
    required super.assignee,
    super.dueDate,
    super.isCompleted,
    super.completedAt,
    super.completedBy,
    required super.createdAt,
  });

  /// Factory constructor untuk memetakan response JSON dari Supabase
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      assignee: json['assignee'] as String? ?? 'both',
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      completedBy: json['completed_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Konversi data Model ke payload JSON untuk dikirim ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'created_by': createdBy,
      'title': title,
      if (description != null) 'description': description,
      'assignee': assignee,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (completedBy != null) 'completed_by': completedBy,
    };
  }

  /// Helper untuk konversi Entity ke Model
  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      familyId: entity.familyId,
      createdBy: entity.createdBy,
      title: entity.title,
      description: entity.description,
      assignee: entity.assignee,
      dueDate: entity.dueDate,
      isCompleted: entity.isCompleted,
      completedAt: entity.completedAt,
      completedBy: entity.completedBy,
      createdAt: entity.createdAt,
    );
  }
}
