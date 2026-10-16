import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import 'package:homey/features/auth/presentation/cubit/family_cubit.dart';
import 'package:homey/features/auth/presentation/cubit/family_state.dart';
import 'package:homey/features/auth/presentation/widgets/family_pairing_dialog.dart';
import 'package:homey/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:homey/features/finance/presentation/cubit/finance_state.dart';
import '../widgets/budget_highlight_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/focus_tasks_section.dart';

/// Halaman Beranda (Dashboard) utama yang terintegrasi live dengan Supabase
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sapaan Personal & Avatar (Live dari FamilyCubit)
              BlocBuilder<FamilyCubit, FamilyState>(
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
                              border: Border.all(
                                color: AppColors.accentYellow,
                              ),
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
              ),
              const SizedBox(height: 20),

              // 2. Quick Stats / Highlight Finansial Live dari Supabase (FinanceCubit)
              BlocBuilder<FinanceCubit, FinanceState>(
                builder: (context, state) {
                  String remainingBudget = 'Rp 0';
                  String todayExpense = 'Rp 0';

                  if (state is FinanceLoaded) {
                    remainingBudget = currencyFormatter.format(state.balance);

                    final today = DateTime.now();
                    final todayTotal = state.transactions
                        .where((t) =>
                            t.isExpense &&
                            t.transactionDate.year == today.year &&
                            t.transactionDate.month == today.month &&
                            t.transactionDate.day == today.day)
                        .fold(0.0, (sum, item) => sum + item.amount);

                    todayExpense = currencyFormatter.format(todayTotal);
                  }

                  return BudgetHighlightCard(
                    remainingBudget: remainingBudget,
                    todayExpense: todayExpense,
                    onDetailPressed: onNavigateToFinance,
                  );
                },
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
