import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_radii.dart';
import '../../constants/app_shadows.dart';
import '../../di/injection_container.dart';
import '../responsive/responsive_layout.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../../features/dashboard/presentation/widgets/add_action_bottom_sheet.dart';
import '../../../features/todo/presentation/pages/agenda_page.dart';
import '../../../features/todo/presentation/cubit/task_cubit.dart';
import '../../../features/todo/presentation/widgets/add_task_bottom_sheet.dart';
import '../../../features/meal_planner/presentation/cubit/meal_plan_cubit.dart';
import '../../../features/meal_planner/presentation/widgets/add_meal_plan_bottom_sheet.dart';
import '../../../features/auth/presentation/cubit/family_cubit.dart';
import '../../../features/auth/presentation/cubit/family_state.dart';
import '../../../features/auth/presentation/pages/settings_page.dart';
import '../../../features/auth/presentation/widgets/family_pairing_dialog.dart';
import '../../../features/finance/presentation/cubit/finance_cubit.dart';
import '../../../features/finance/presentation/pages/finance_page.dart';
import '../../../features/finance/presentation/widgets/add_transaction_bottom_sheet.dart';

/// MainLayout adaptif:
/// - Mobile: Menggunakan Bottom Navigation Bar kustom + Center FAB
/// - Web / Desktop / Tablet: Menggunakan Left Sidebar Navigation yang elegan & fungsional
class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAddModal(BuildContext context) {
    String familyId = '00000000-0000-0000-0000-000000000001';
    String userId = '6471baf6-3b32-4a9b-9ee2-6ada214e4eb2';

    final familyState = context.read<FamilyCubit>().state;
    if (familyState is FamilyLoaded) {
      if (familyState.family != null) familyId = familyState.family!.id;
      userId = familyState.profile.id;
    }

    AddActionBottomSheet.show(
      context,
      onAddFinance: () {
        _onTabSelected(2);
        AddTransactionBottomSheet.show(
          context,
          familyId: familyId,
          userId: userId,
        );
      },
      onAddTask: () {
        _onTabSelected(1);
        AddTaskBottomSheet.show(
          context,
          familyId: familyId,
          userId: userId,
          initialDueDate: DateTime.now(),
        );
      },
      onAddMeal: () {
        _onTabSelected(1);
        AddMealPlanBottomSheet.show(
          context,
          familyId: familyId,
          userId: userId,
          initialDate: DateTime.now(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<FamilyCubit>()..loadFamilyData(),
        ),
        BlocProvider(
          create: (_) => sl<FinanceCubit>()
            ..watchFamilyTransactions('00000000-0000-0000-0000-000000000001'),
        ),
        BlocProvider(
          create: (_) => sl<TaskCubit>()
            ..watchTasks('00000000-0000-0000-0000-000000000001'),
        ),
        BlocProvider(
          create: (_) => sl<MealPlanCubit>()
            ..watchFamilyMealPlans('00000000-0000-0000-0000-000000000001'),
        ),
      ],
      child: Builder(
        builder: (innerContext) {
          final pages = [
            DashboardPage(
              onNavigateToFinance: () => _onTabSelected(2),
              onNavigateToAgenda: () => _onTabSelected(1),
              onNavigateToSettings: () => _onTabSelected(3),
            ),
            const AgendaPage(),
            const FinancePage(),
            const SettingsPage(),
          ];

          return BlocListener<FamilyCubit, FamilyState>(
            listener: (context, state) {
              if (state is FamilyLoaded && state.family != null) {
                context.read<FinanceCubit>().watchFamilyTransactions(state.family!.id);
                context.read<TaskCubit>().watchTasks(state.family!.id);
                context.read<MealPlanCubit>().watchFamilyMealPlans(state.family!.id);
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: ResponsiveLayout(
                // Tampilan Mobile
                mobile: Stack(
                  children: [
                    IndexedStack(
                      index: _currentIndex,
                      children: pages,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildBottomNav(innerContext),
                    ),
                  ],
                ),
                // Tampilan Web & Desktop
                desktop: Row(
                  children: [
                    // Sidebar Kiri
                    _buildDesktopSidebar(innerContext),
                    // Konten Utama
                    Expanded(
                      child: Container(
                        color: AppColors.background,
                        child: IndexedStack(
                          index: _currentIndex,
                          children: pages,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Sidebar Desktop & Web
  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // App Brand & Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentTerracotta,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentTerracotta.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Homey',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    Text(
                      'Harmoni Pasutri',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // User & Family Status Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<FamilyCubit, FamilyState>(
              builder: (context, state) {
                String userName = 'Pasangan';
                String role = 'Pasutri';
                bool isConnected = false;

                if (state is FamilyLoaded) {
                  userName = state.profile.fullName ?? state.profile.role;
                  role = state.profile.role;
                  isConnected = state.hasFamily;
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.accentTerracotta.withValues(alpha: 0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'H',
                          style: const TextStyle(
                            color: AppColors.accentTerracotta,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isConnected
                                        ? AppColors.accentGreen
                                        : AppColors.accentYellow,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    isConnected ? '$role • Terkoneksi' : '$role • Belum Pasangan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isConnected
                                          ? AppColors.accentGreen
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isConnected)
                        IconButton(
                          icon: const Icon(
                            Icons.link_rounded,
                            color: AppColors.accentTerracotta,
                            size: 18,
                          ),
                          tooltip: 'Hubungkan Pasangan',
                          onPressed: () => FamilyPairingDialog.show(context),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Tombol "+ Tambah Cepat" Desktop
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton.icon(
                onPressed: () => _openAddModal(context),
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Tambah Cepat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTerracotta,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: AppColors.accentTerracotta.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarNavItem(
                  index: 0,
                  label: 'Beranda',
                  icon: Icons.home_rounded,
                ),
                const SizedBox(height: 6),
                _buildSidebarNavItem(
                  index: 1,
                  label: 'Agenda & Tugas',
                  icon: Icons.calendar_today_rounded,
                ),
                const SizedBox(height: 6),
                _buildSidebarNavItem(
                  index: 2,
                  label: 'Buku Kas Pasutri',
                  icon: Icons.account_balance_wallet_rounded,
                ),
                const SizedBox(height: 6),
                _buildSidebarNavItem(
                  index: 3,
                  label: 'Pengaturan',
                  icon: Icons.settings_rounded,
                ),
              ],
            ),
          ),

          // Footer Sidebar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.accentGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saling terhubung setiap hari',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentGreen.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Item Navigasi Sidebar Desktop
  Widget _buildSidebarNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: isSelected
            ? AppColors.accentTerracotta.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _onTabSelected(index),
          borderRadius: BorderRadius.circular(14),
          hoverColor: AppColors.accentTerracotta.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? AppColors.accentTerracotta
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.accentTerracotta
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.accentTerracotta,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom Navigation Bar untuk Tampilan Mobile
  Widget _buildBottomNav(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Navigation Bar Container
        Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.bottomSheetRadius,
            boxShadow: AppShadows.bottomNav,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBottomNavItem(
                index: 0,
                label: 'Beranda',
                icon: Icons.home_rounded,
              ),
              _buildBottomNavItem(
                index: 1,
                label: 'Agenda',
                icon: Icons.calendar_today_rounded,
              ),
              // Spacer untuk FAB tengah
              const SizedBox(width: 48),
              _buildBottomNavItem(
                index: 2,
                label: 'Keuangan',
                icon: Icons.account_balance_wallet_rounded,
              ),
              _buildBottomNavItem(
                index: 3,
                label: 'Setting',
                icon: Icons.settings_rounded,
              ),
            ],
          ),
        ),

        // FAB Menonjol di Tengah
        Positioned(
          top: -24,
          child: GestureDetector(
            onTap: () => _openAddModal(context),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.accentTerracotta,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTerracotta.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.accentTerracotta : AppColors.textMuted;

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
