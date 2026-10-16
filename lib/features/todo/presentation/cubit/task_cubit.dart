import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_state.dart';

/// Cubit yang mengelola state daftar tugas keluarga secara Real-time
class TaskCubit extends Cubit<TaskState> {
  final TaskRepository _taskRepository;
  StreamSubscription<List<TaskEntity>>? _taskSubscription;

  TaskCubit({required TaskRepository taskRepository})
      : _taskRepository = taskRepository,
        super(const TaskInitial());

  /// Memulai sinkronisasi stream real-time dari Supabase
  void watchTasks(String familyId) {
    emit(const TaskLoading());
    _taskSubscription?.cancel();

    _taskSubscription = _taskRepository.watchFamilyTasks(familyId).listen(
      (tasks) {
        // Setiap ada perubahan dari HP suami atau istri, stream langsung memancarkan data terbaru
        emit(TaskLoaded(tasks: tasks));
      },
      onError: (error) {
        emit(TaskError('Gagal menyinkronkan tugas: ${error.toString()}'));
      },
    );
  }

  /// Toggle checklist tugas (misal: saat dicentang oleh istri / suami)
  Future<void> toggleTask({
    required String taskId,
    required bool isCompleted,
    required String currentUserId,
  }) async {
    try {
      await _taskRepository.toggleTaskCompletion(
        taskId: taskId,
        isCompleted: isCompleted,
        completedBy: currentUserId,
      );
      // Catatan: Tidak perlu memanggil emit manual di sini, karena Supabase Realtime
      // akan otomatis mengirim event UPDATE dan stream listener di atas akan meng-emit TaskLoaded.
    } catch (e) {
      emit(TaskError('Gagal memperbarui status tugas: ${e.toString()}'));
    }
  }

  /// Menambahkan tugas baru
  Future<void> addTask(TaskEntity task) async {
    try {
      await _taskRepository.createTask(task);
    } catch (e) {
      emit(TaskError('Gagal menambahkan tugas: ${e.toString()}'));
    }
  }

  /// Menghapus tugas
  Future<void> deleteTask(String taskId) async {
    try {
      await _taskRepository.deleteTask(taskId);
    } catch (e) {
      emit(TaskError('Gagal menghapus tugas: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _taskSubscription?.cancel();
    return super.close();
  }
}
