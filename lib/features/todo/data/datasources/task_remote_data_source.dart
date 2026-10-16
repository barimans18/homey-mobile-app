import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Stream<List<TaskModel>> watchFamilyTasks(String familyId);
  Future<void> toggleTaskCompletion({
    required String taskId,
    required bool isCompleted,
    required String completedBy,
  });
  Future<void> createTask(TaskModel task);
  Future<void> deleteTask(String taskId);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final SupabaseClient _client;

  TaskRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<TaskModel>> watchFamilyTasks(String familyId) {
    // Menggunakan .stream(primaryKey: ['id']) sesuai standar di skills.md
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('is_completed', ascending: true)
        .order('due_date', ascending: true)
        .map((data) => data.map((json) => TaskModel.fromJson(json)).toList());
  }

  @override
  Future<void> toggleTaskCompletion({
    required String taskId,
    required bool isCompleted,
    required String completedBy,
  }) async {
    await _client.from('tasks').update({
      'is_completed': isCompleted,
      'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
      'completed_by': isCompleted ? completedBy : null,
    }).eq('id', taskId);
  }

  @override
  Future<void> createTask(TaskModel task) async {
    await _client.from('tasks').insert(task.toJson());
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }
}
