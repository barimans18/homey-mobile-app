import 'package:get_it/get_it.dart';

import '../../features/auth/presentation/cubit/role_selection_cubit.dart';
import '../../features/todo/data/datasources/task_remote_data_source.dart';
import '../../features/todo/data/repositories/task_repository_impl.dart';
import '../../features/todo/domain/repositories/task_repository.dart';
import '../../features/todo/presentation/cubit/task_cubit.dart';

final sl = GetIt.instance;

/// Inisialisasi Service Locator (Dependency Injection)
Future<void> initDependencies() async {
  // ----------------------------------------------------
  // Feature: Auth
  // ----------------------------------------------------
  sl.registerFactory(() => RoleSelectionCubit());

  // ----------------------------------------------------
  // Feature: Todo / Agenda (Real-time)
  // ----------------------------------------------------
  // Data Source
  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(remoteDataSource: sl()),
  );

  // Cubit
  sl.registerFactory(
    () => TaskCubit(taskRepository: sl()),
  );
}
