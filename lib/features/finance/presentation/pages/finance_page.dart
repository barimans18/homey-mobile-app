import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/presentation/widgets/custom_app_bar.dart';
import 'package:homey/features/auth/presentation/cubit/family_cubit.dart';
import 'package:homey/features/auth/presentation/cubit/family_state.dart';
import '../cubit/finance_cubit.dart';
import '../cubit/finance_state.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/transaction_card.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil familyId dari FamilyCubit jika tersedia, fallback ke default ID
    String familyId = '00000000-0000-0000-0000-000000000001';
    String userId = '6471baf6-3b32-4a9b-9ee2-6ada214e4eb2';

    final familyState = context.watch<FamilyCubit>().state;
    if (familyState is FamilyLoaded) {
      if (familyState.family != null) {
        familyId = familyState.family!.id;
      }
      userId = familyState.profile.id;
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Buku Kas 💰',
        subtitle: 'Catatan keuangan bersama pasangan',
        actions: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.accentTerracotta,
              borderRadius: AppRadii.buttonRadius,
              boxShadow: AppShadows.soft,
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              tooltip: 'Catat Transaksi',
              onPressed: () {
                AddTransactionBottomSheet.show(
                  context,
                  familyId: familyId,
                  userId: userId,
                );
              },
            ),
          ),
        ],
      ),
      body: BlocBuilder<FinanceCubit, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentTerracotta,
              ),
            );
          }

          if (state is FinanceError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<FinanceCubit>().watchFamilyTransactions(familyId);
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final loadedState = state is FinanceLoaded
              ? state
              : const FinanceLoaded(transactions: []);

          final transactions = loadedState.filteredTransactions;
          final totalIncome = loadedState.totalIncome;
          final totalExpense = loadedState.totalExpense;
          final balance = loadedState.balance;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Kartu Ringkasan Saldo Bersama
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.cardRadius,
                    boxShadow: AppShadows.soft,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sisa Saldo Kas Bersama',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.sync_rounded,
                                  size: 13,
                                  color: AppColors.accentGreen,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Real-time',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormatter.format(balance),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 14),

                      // Baris Pemasukan & Pengeluaran
                      Row(
                        children: [
                          // Pemasukan
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pemasukan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      Text(
                                        currencyFormatter.format(totalIncome),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accentGreen,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Pengeluaran
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentTerracotta.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: AppColors.accentTerracotta,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pengeluaran',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      Text(
                                        currencyFormatter.format(totalExpense),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accentTerracotta,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Visualisasi Budget per Kategori (Progress Bar)
                BudgetProgressCard(
                  categoryExpenses: loadedState.expensesByCategory,
                  totalExpense: totalExpense,
                ),
                const SizedBox(height: 24),

                // 3. Tab Filter Transaksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Kas Bersama',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '${transactions.length} transaksi',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        context,
                        label: 'Semua',
                        filterValue: 'all',
                        currentFilter: loadedState.activeFilter,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Pengeluaran',
                        filterValue: 'expense',
                        currentFilter: loadedState.activeFilter,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Pemasukan',
                        filterValue: 'income',
                        currentFilter: loadedState.activeFilter,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Daftar Transaksi
                if (transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadii.cardRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accentYellow.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 32,
                            color: AppColors.accentTerracotta,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum Ada Catatan Transaksi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ketuk tombol "+ Catat Transaksi" untuk menambahkan pengeluaran atau pemasukan baru.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...transactions.map(
                    (item) => TransactionCard(
                      transaction: item,
                      onDelete: () {
                        _showDeleteConfirm(context, item.id);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required String filterValue,
    required String currentFilter,
  }) {
    final isSelected = currentFilter == filterValue;
    return GestureDetector(
      onTap: () {
        context.read<FinanceCubit>().setFilter(filterValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentTerracotta : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentTerracotta : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
        title: const Text('Hapus Transaksi?'),
        content: const Text(
          'Transaksi ini akan dihapus dari buku kas bersama keluarga Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<FinanceCubit>().deleteTransaction(id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
