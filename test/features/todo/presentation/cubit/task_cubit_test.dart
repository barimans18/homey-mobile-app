import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:homey/features/todo/domain/entities/task_entity.dart';
import 'package:homey/features/todo/domain/repositories/task_repository.dart';
import 'package:homey/features/todo/presentation/cubit/task_cubit.dart';
import 'package:homey/features/todo/presentation/cubit/task_state.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  group('TaskCubit Real-time Tests', () {
    late MockTaskRepository mockRepository;
    late TaskCubit cubit;

    final tTasks = [
      TaskEntity(
        id: 'task-1',
        familyId: 'family-1',
        createdBy: 'user-suami',
        title: 'Beli Stok Susu & Popok',
        assignee: 'suami',
        isCompleted: false,
        createdAt: DateTime.now(),
      ),
    ];

    setUp(() {
      mockRepository = MockTaskRepository();
      cubit = TaskCubit(taskRepository: mockRepository);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state harus TaskInitial', () {
      expect(cubit.state, equals(const TaskInitial()));
    });

    blocTest<TaskCubit, TaskState>(
      'Emits [TaskLoading, TaskLoaded] saat stream Supabase memancarkan data baru',
      build: () {
        when(() => mockRepository.watchFamilyTasks('family-1'))
            .thenAnswer((_) => Stream.value(tTasks));
        return cubit;
      },
      act: (c) => c.watchTasks('family-1'),
      expect: () => [
        const TaskLoading(),
        TaskLoaded(tasks: tTasks),
      ],
      verify: (_) {
        verify(() => mockRepository.watchFamilyTasks('family-1')).called(1);
      },
    );

    blocTest<TaskCubit, TaskState>(
      'Memanggil repository.toggleTaskCompletion saat toggleTask dipicu',
      build: () {
        when(() => mockRepository.toggleTaskCompletion(
              taskId: 'task-1',
              isCompleted: true,
              completedBy: 'user-istri',
            )).thenAnswer((_) async {});
        return cubit;
      },
      act: (c) => c.toggleTask(
        taskId: 'task-1',
        isCompleted: true,
        currentUserId: 'user-istri',
      ),
      verify: (_) {
        verify(() => mockRepository.toggleTaskCompletion(
              taskId: 'task-1',
              isCompleted: true,
              completedBy: 'user-istri',
            )).called(1);
      },
    );
  });
}
