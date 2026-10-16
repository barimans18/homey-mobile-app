import '../entities/task_entity.dart';

/// Interface Repository untuk operasi data Task / Agenda
abstract class TaskRepository {
  /// Stream real-time seluruh tugas keluarga (auto-sync saat suami/istri mengubah data)
  Stream<List<TaskEntity>> watchFamilyTasks(String familyId);

  /// Mengubah status penyelesaian tugas (selesai / belum selesai)
  Future<void> toggleTaskCompletion({
    required String taskId,
    required bool isCompleted,
    required String completedBy,
  });

  /// Menambahkan tugas baru
  Future<void> createTask(TaskEntity task);

  /// Menghapus tugas
  Future<void> deleteTask(String taskId);
}
