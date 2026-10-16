import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

/// Implementasi TaskRepository di Layer Data
class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;

  TaskRepositoryImpl({required TaskRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<TaskEntity>> watchFamilyTasks(String familyId) {
    return _remoteDataSource.watchFamilyTasks(familyId);
  }

  @override
  Future<void> toggleTaskCompletion({
    required String taskId,
    required bool isCompleted,
    required String completedBy,
  }) async {
    await _remoteDataSource.toggleTaskCompletion(
      taskId: taskId,
      isCompleted: isCompleted,
      completedBy: completedBy,
    );
  }

  @override
  Future<void> createTask(TaskEntity task) async {
    final model = TaskModel.fromEntity(task);
    await _remoteDataSource.createTask(model);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _remoteDataSource.deleteTask(taskId);
  }
}
