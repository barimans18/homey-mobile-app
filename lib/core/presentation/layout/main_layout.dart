import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_radii.dart';
import '../../constants/app_shadows.dart';
import '../../di/injection_container.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../../features/dashboard/presentation/widgets/add_action_bottom_sheet.dart';
import '../../../features/todo/presentation/pages/agenda_page.dart';
import '../../../features/todo/presentation/cubit/task_cubit.dart';
import '../../../features/finance/presentation/pages/finance_page.dart';
import '../../../features/auth/presentation/pages/settings_page.dart';

/// MainLayout dengan Bottom Navigation Bar kustom dan Floating Action Button (FAB) menonjol di tengah
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

  void _openAddModal() {
    AddActionBottomSheet.show(
      context,
      onAddFinance: () {
        _onTabSelected(2); // Pindah ke Keuangan
      },
      onAddTask: () {
        _onTabSelected(1); // Pindah ke Agenda
      },
      onAddMeal: () {
        _onTabSelected(1); // Pindah ke Meal Plan / Agenda
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onNavigateToFinance: () => _onTabSelected(2),
        onNavigateToAgenda: () => _onTabSelected(1),
        onNavigateToSettings: () => _onTabSelected(3),
      ),
      BlocProvider(
        create: (context) => sl<TaskCubit>()..watchTasks('00000000-0000-0000-0000-000000000000'),
        child: const AgendaPage(),
      ),
      const FinancePage(),
      const SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Konten Layar Aktif
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),

          // Custom Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
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
              // Tab 1: Beranda
              _buildNavItem(
                index: 0,
                label: 'Beranda',
                icon: Icons.home_rounded,
              ),
              // Tab 2: Agenda
              _buildNavItem(
                index: 1,
                label: 'Agenda',
                icon: Icons.calendar_today_rounded,
              ),
              // Spacer untuk FAB tengah
              const SizedBox(width: 48),
              // Tab 3: Keuangan
              _buildNavItem(
                index: 2,
                label: 'Keuangan',
                icon: Icons.account_balance_wallet_rounded,
              ),
              // Tab 4: Setting
              _buildNavItem(
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
            onTap: _openAddModal,
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

  Widget _buildNavItem({
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
