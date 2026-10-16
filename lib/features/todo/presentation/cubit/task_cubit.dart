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
    final currentState = state;
    // 1. Optimistic UI update: langsung ubah status di layar secara instan
    if (currentState is TaskLoaded) {
      final updatedTasks = currentState.tasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(
            isCompleted: isCompleted,
            completedBy: isCompleted ? currentUserId : null,
            completedAt: isCompleted ? DateTime.now() : null,
          );
        }
        return t;
      }).toList();
      emit(TaskLoaded(tasks: updatedTasks));
    }

    try {
      await _taskRepository.toggleTaskCompletion(
        taskId: taskId,
        isCompleted: isCompleted,
        completedBy: currentUserId,
      );
    } catch (e) {
      // Revert jika gagal
      emit(currentState);
      emit(TaskError('Gagal memperbarui status tugas: ${e.toString()}'));
    }
  }

  /// Menambahkan tugas baru
  Future<void> addTask(TaskEntity task) async {
    final currentState = state;
    if (currentState is TaskLoaded) {
      final updatedTasks = [task, ...currentState.tasks];
      emit(TaskLoaded(tasks: updatedTasks));
    }
    try {
      await _taskRepository.createTask(task);
    } catch (e) {
      emit(currentState);
      emit(TaskError('Gagal menambahkan tugas: ${e.toString()}'));
    }
  }

  /// Menghapus tugas secara instan dari layar (optimistic) & sinkron ke Supabase
  Future<void> deleteTask(String taskId) async {
    final currentState = state;
    // 1. Optimistic UI update: langsung buang dari layar tanpa menunggu roundtrip network
    if (currentState is TaskLoaded) {
      final updatedTasks = currentState.tasks.where((t) => t.id != taskId).toList();
      emit(TaskLoaded(tasks: updatedTasks));
    }

    try {
      await _taskRepository.deleteTask(taskId);
    } catch (e) {
      // Kembalikan ke state semula jika network error
      emit(currentState);
      emit(TaskError('Gagal menghapus tugas: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _taskSubscription?.cancel();
    return super.close();
  }
}
