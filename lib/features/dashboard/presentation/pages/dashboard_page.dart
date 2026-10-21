import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/presentation/responsive/responsive_layout.dart';
import 'package:homey/features/auth/presentation/cubit/family_cubit.dart';
import 'package:homey/features/auth/presentation/cubit/family_state.dart';
import 'package:homey/features/auth/presentation/widgets/family_pairing_dialog.dart';
import 'package:homey/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:homey/features/finance/presentation/cubit/finance_state.dart';
import '../widgets/budget_highlight_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/focus_tasks_section.dart';
import '../widgets/meal_plan_carousel_section.dart';
import 'package:homey/features/meal_planner/presentation/cubit/meal_plan_cubit.dart';
import 'package:homey/features/meal_planner/presentation/pages/meal_planner_page.dart';

/// Halaman Beranda (Dashboard) utama yang terintegrasi live dengan Supabase
/// Dilengkapi tampilan responsif untuk Mobile dan Desktop/Web.
class DashboardPage extends StatelessWidget {
  final VoidCallback onNavigateToFinance;
  final VoidCallback onNavigateToAgenda;
  final VoidCallback onNavigateToSettings;

  const DashboardPage({
    super.key,
    required this.onNavigateToFinance,
    required this.onNavigateToAgenda,
    required this.onNavigateToSettings,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ResponsiveContentContainer(
          padding: EdgeInsets.fromLTRB(
            context.isDesktop ? 32 : 24,
            16,
            context.isDesktop ? 32 : 24,
            context.isDesktop ? 32 : 120,
          ),
          child: SingleChildScrollView(
            child: ResponsiveLayout(
              // Tampilan Mobile (1 Kolom Vertikal)
              mobile: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(context),
                  const SizedBox(height: 20),
                  _buildBudgetSection(context, currencyFormatter),
                  const SizedBox(height: 24),
                  FocusTasksSection(onSeeAllPressed: onNavigateToAgenda),
                  const SizedBox(height: 18),
                  _buildMealPlanSection(context),
                ],
              ),
              // Tampilan Web & Desktop (Grid 2 Kolom)
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kolom Kiri: Header & Keuangan
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(context),
                        const SizedBox(height: 20),
                        _buildBudgetSection(context, currencyFormatter),
                      ],
                    ),
                  ),
                  const SizedBox(width: 28),
                  // Kolom Kanan: Fokus Agenda & Menu Makan
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FocusTasksSection(onSeeAllPressed: onNavigateToAgenda),
                        const SizedBox(height: 24),
                        _buildMealPlanSection(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Sapaan Personal & Status Pasangan
  Widget _buildHeaderSection(BuildContext context) {
    return BlocBuilder<FamilyCubit, FamilyState>(
      builder: (context, state) {
        String greeting = 'Pasutri';
        bool hasFamily = false;

        if (state is FamilyLoaded) {
          final role = state.profile.role.toLowerCase();
          greeting = role == 'suami' ? 'Suami' : 'Istri';
          if (state.profile.fullName != null &&
              state.profile.fullName!.isNotEmpty) {
            greeting = state.profile.fullName!;
          }
          hasFamily = state.hasFamily;
        }

        return Column(
          children: [
            DashboardHeader(
              greetingName: greeting,
              avatarUrl: state is FamilyLoaded ? state.profile.avatarUrl : null,
              role: state is FamilyLoaded ? state.profile.role : null,
              onProfileTap: onNavigateToSettings,
            ),
            if (!hasFamily) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => FamilyPairingDialog.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withValues(alpha: 0.25),
                    borderRadius: AppRadii.cardRadius,
                    border: Border.all(color: AppColors.accentYellow),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.vpn_key_rounded,
                        color: AppColors.accentTerracotta,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Belum terhubung ke pasangan? Masukkan Kode Keluarga di sini ➔',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Highlight Keuangan Bersama
  Widget _buildBudgetSection(
    BuildContext context,
    NumberFormat currencyFormatter,
  ) {
    return BlocBuilder<FinanceCubit, FinanceState>(
      builder: (context, state) {
        String remainingBudget = 'Rp 0';
        String todayExpense = 'Rp 0';

        if (state is FinanceLoaded) {
          remainingBudget = currencyFormatter.format(state.balance);

          final today = DateTime.now();
          final todayTotal = state.transactions
              .where(
                (t) =>
                    t.isExpense &&
                    t.transactionDate.year == today.year &&
                    t.transactionDate.month == today.month &&
                    t.transactionDate.day == today.day,
              )
              .fold(0.0, (sum, item) => sum + item.amount);

          todayExpense = currencyFormatter.format(todayTotal);
        }

        return BudgetHighlightCard(
          remainingBudget: remainingBudget,
          todayExpense: todayExpense,
          onDetailPressed: onNavigateToFinance,
        );
      },
    );
  }

  /// Carousel Menu Makan Keluarga
  Widget _buildMealPlanSection(BuildContext context) {
    return MealPlanCarouselSection(
      onSeeAllPressed: () {
        final mealPlanCubit = context.read<MealPlanCubit>();
        final familyCubit = context.read<FamilyCubit>();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: mealPlanCubit),
                BlocProvider.value(value: familyCubit),
              ],
              child: const MealPlannerPage(),
            ),
          ),
        );
      },
    );
  }
}
