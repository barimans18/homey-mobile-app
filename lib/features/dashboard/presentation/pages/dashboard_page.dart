import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/budget_highlight_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/focus_tasks_section.dart';

/// Halaman Beranda (Dashboard) utama sesuai prototipe HTML & PRD
class DashboardPage extends StatelessWidget {
  final VoidCallback onNavigateToFinance;
  final VoidCallback onNavigateToAgenda;
  final VoidCallback onNavigateToSettings;
  final String greetingName;

  const DashboardPage({
    super.key,
    required this.onNavigateToFinance,
    required this.onNavigateToAgenda,
    required this.onNavigateToSettings,
    this.greetingName = 'Pasutri',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sapaan Personal & Avatar
              DashboardHeader(
                greetingName: greetingName,
                onProfileTap: onNavigateToSettings,
              ),
              const SizedBox(height: 20),

              // 2. Quick Stats / Highlight Finansial (Sisa Budget Bulan Ini)
              BudgetHighlightCard(
                remainingBudget: 'Rp 4.250.000',
                todayExpense: 'Rp 165.000',
                onDetailPressed: onNavigateToFinance,
              ),
              const SizedBox(height: 24),

              // 3. Highlight Agenda Hari Ini ("Fokus Hari Ini")
              FocusTasksSection(
                onSeeAllPressed: onNavigateToAgenda,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
