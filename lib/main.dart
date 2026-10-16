import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Dependency Injection (GetIt)
  await di.initDependencies();

  // 2. Inisialisasi Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConstants.anonKey,
    );
    developer.log('Supabase initialized successfully', name: 'HomeyApp');
  } catch (e) {
    developer.log(
      'Supabase initialization skipped or failed (gunakan kredensial valid pada production): $e',
      name: 'HomeyApp',
      error: e,
    );
  }

  runApp(const HomeyApp());
}

/// Root Widget aplikasi Homey
class HomeyApp extends StatelessWidget {
  const HomeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Homey',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
