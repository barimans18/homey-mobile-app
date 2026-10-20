import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/injection_container.dart';
import '../presentation/layout/main_layout.dart';
import '../../features/auth/presentation/cubit/family_cubit.dart';
import '../../features/auth/presentation/cubit/role_selection_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/meal_planner/presentation/cubit/meal_plan_cubit.dart';
import '../../features/meal_planner/presentation/pages/meal_planner_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

/// Konfigurasi routing aplikasi menggunakan go_router
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String mealPlanner = '/meal-planner';

  static const String initial = splash;

  static final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => sl<RoleSelectionCubit>()),
            BlocProvider(create: (context) => sl<FamilyCubit>()..loadFamilyData()),
          ],
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: mealPlanner,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<FamilyCubit>()..loadFamilyData()),
            BlocProvider(create: (_) => sl<MealPlanCubit>()..watchFamilyMealPlans('00000000-0000-0000-0000-000000000001')),
          ],
          child: const MealPlannerPage(),
        ),
      ),
    ],
  );
}
