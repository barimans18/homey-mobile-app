import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/injection_container.dart';
import '../presentation/layout/main_layout.dart';
import '../../features/auth/presentation/cubit/role_selection_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';

/// Konfigurasi routing aplikasi menggunakan go_router
class AppRouter {
  AppRouter._();

  static const String login = '/login';
  static const String home = '/home';

  static const String initial = login;

  static final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => BlocProvider(
          create: (context) => sl<RoleSelectionCubit>(),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const MainLayout(),
      ),
    ],
  );
}
