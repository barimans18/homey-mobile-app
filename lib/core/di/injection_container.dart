import 'package:get_it/get_it.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/session_storage_service.dart';
import '../../features/auth/presentation/cubit/role_selection_cubit.dart';
import '../../features/auth/data/datasources/family_remote_data_source.dart';
import '../../features/auth/data/repositories/family_repository_impl.dart';
import '../../features/auth/domain/repositories/family_repository.dart';
import '../../features/auth/presentation/cubit/family_cubit.dart';
import '../../features/finance/data/datasources/finance_remote_data_source.dart';
import '../../features/finance/data/repositories/finance_repository_impl.dart';
import '../../features/finance/domain/repositories/finance_repository.dart';
import '../../features/finance/presentation/cubit/finance_cubit.dart';
import '../../features/todo/data/datasources/task_remote_data_source.dart';
import '../../features/todo/data/repositories/task_repository_impl.dart';
import '../../features/todo/domain/repositories/task_repository.dart';
import '../../features/todo/presentation/cubit/task_cubit.dart';
import '../../features/meal_planner/data/datasources/meal_plan_remote_data_source.dart';
import '../../features/meal_planner/data/repositories/meal_plan_repository_impl.dart';
import '../../features/meal_planner/domain/repositories/meal_plan_repository.dart';
import '../../features/meal_planner/presentation/cubit/meal_plan_cubit.dart';

final sl = GetIt.instance;

/// Inisialisasi Service Locator (Dependency Injection)
Future<void> initDependencies() async {
  // ----------------------------------------------------
  // Core: Local Storage & Session
  // ----------------------------------------------------
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<SessionStorageService>(
    () => SessionStorageService(prefs: sl()),
  );

  // ----------------------------------------------------
  // Feature: Auth & Family Pairing
  // ----------------------------------------------------
  sl.registerFactory(() => RoleSelectionCubit());
  sl.registerLazySingleton<FamilyRemoteDataSource>(
    () => FamilyRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<FamilyRepository>(
    () => FamilyRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(
    () => FamilyCubit(familyRepository: sl()),
  );

  // ----------------------------------------------------
  // Feature: Finance / Joint Ledger (Real-time)
  // ----------------------------------------------------
  sl.registerLazySingleton<FinanceRemoteDataSource>(
    () => FinanceRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<FinanceRepository>(
    () => FinanceRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(
    () => FinanceCubit(financeRepository: sl()),
  );

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

  // ----------------------------------------------------
  // Feature: Meal Planner (Real-time)
  // ----------------------------------------------------
  sl.registerLazySingleton<MealPlanRemoteDataSource>(
    () => MealPlanRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<MealPlanRepository>(
    () => MealPlanRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(
    () => MealPlanCubit(repository: sl()),
  );
}
