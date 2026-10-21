import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/presentation/responsive/responsive_layout.dart';
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

  Future<void> _pickMonth(BuildContext context, DateTime currentMonth) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'PILIH BULAN TRANSAKSI',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentTerracotta,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      context.read<FinanceCubit>().setMonth(picked);
    }
  }

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
              : FinanceLoaded(transactions: const []);

          final transactions = loadedState.filteredTransactions;
          final totalIncome = loadedState.totalIncome;
          final totalExpense = loadedState.totalExpense;
          final balance = loadedState.balance;

          return ResponsiveContentContainer(
            padding: EdgeInsets.fromLTRB(
              context.isDesktop ? 32 : 24,
              8,
              context.isDesktop ? 32 : 24,
              context.isDesktop ? 32 : 150,
            ),
            child: SingleChildScrollView(
              child: ResponsiveLayout(
                // Mobile: 1 Kolom Vertikal
                mobile: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSelectorBar(context, loadedState),
                    const SizedBox(height: 16),
                    _buildBalanceCard(
                      currencyFormatter,
                      balance,
                      totalIncome,
                      totalExpense,
                      loadedState.selectedMonth,
                    ),
                    const SizedBox(height: 20),
                    BudgetProgressCard(
                      categoryExpenses: loadedState.expensesByCategory,
                      totalExpense: totalExpense,
                    ),
                    const SizedBox(height: 24),
                    _buildTransactionHeader(
                      context,
                      transactions.length,
                      loadedState.selectedMonth,
                    ),
                    const SizedBox(height: 12),
                    _buildFilterChips(context, loadedState.activeFilter),
                    const SizedBox(height: 16),
                    _buildTransactionList(
                      context,
                      transactions,
                      loadedState.selectedMonth,
                    ),
                  ],
                ),
                // Desktop: 2 Kolom dengan Month Selector di Atas
                desktop: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSelectorBar(context, loadedState),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kolom Kiri: Ringkasan Saldo & Progress Kategori
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBalanceCard(
                                currencyFormatter,
                                balance,
                                totalIncome,
                                totalExpense,
                                loadedState.selectedMonth,
                              ),
                              const SizedBox(height: 20),
                              BudgetProgressCard(
                                categoryExpenses: loadedState.expensesByCategory,
                                totalExpense: totalExpense,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 28),
                        // Kolom Kanan: Filter & Riwayat Transaksi
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTransactionHeader(
                                context,
                                transactions.length,
                                loadedState.selectedMonth,
                              ),
                              const SizedBox(height: 12),
                              _buildFilterChips(context, loadedState.activeFilter),
                              const SizedBox(height: 16),
                              _buildTransactionList(
                                context,
                                transactions,
                                loadedState.selectedMonth,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  /// Bar Filter Bulan Transaksi
  Widget _buildMonthSelectorBar(BuildContext context, FinanceLoaded state) {
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(state.selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardRadius,
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Icon Kalender & Nama Bulan (Klik untuk DatePicker)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _pickMonth(context, state.selectedMonth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accentTerracotta.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: AppColors.accentTerracotta,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.accentTerracotta,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),

          // Tombol Navigasi Bulan (Prev / Next Month)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    color: AppColors.textPrimary,
                    tooltip: 'Bulan Sebelumnya',
                    onPressed: () => context.read<FinanceCubit>().changeMonth(-1),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    color: AppColors.textPrimary,
                    tooltip: 'Bulan Selanjutnya',
                    onPressed: () => context.read<FinanceCubit>().changeMonth(1),
                  ),
                ),
              ],
            ),
          ),

          // Tombol Kembali ke "Bulan Ini" jika sedang melihat bulan lain
          if (!state.isCurrentMonth) ...[
            const SizedBox(width: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.read<FinanceCubit>().resetToCurrentMonth(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Bulan Ini',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Kartu Ringkasan Saldo Kas Bersama
  Widget _buildBalanceCard(
    NumberFormat currencyFormatter,
    double balance,
    double totalIncome,
    double totalExpense,
    DateTime selectedMonth,
  ) {
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth);

    return Container(
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
              Text(
                'Saldo Kas ($monthName)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
    );
  }

  /// Header Riwayat Kas
  Widget _buildTransactionHeader(
    BuildContext context,
    int count,
    DateTime selectedMonth,
  ) {
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Riwayat Transaksi ($monthName)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        Text(
          '$count transaksi',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  /// Filter Chips (Semua, Pengeluaran, Pemasukan)
  Widget _buildFilterChips(BuildContext context, String currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context,
            label: 'Semua',
            filterValue: 'all',
            currentFilter: currentFilter,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: 'Pengeluaran',
            filterValue: 'expense',
            currentFilter: currentFilter,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: 'Pemasukan',
            filterValue: 'income',
            currentFilter: currentFilter,
          ),
        ],
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
      ),
    );
  }

  /// Daftar Kartu Transaksi
  Widget _buildTransactionList(
    BuildContext context,
    List<dynamic> transactions,
    DateTime selectedMonth,
  ) {
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth);

    if (transactions.isEmpty) {
      return Container(
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
            Text(
              'Belum Ada Catatan Transaksi di $monthName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ketuk tombol "+ Catat Transaksi" untuk menambahkan pengeluaran atau pemasukan baru pada bulan ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: transactions
          .map(
            (item) => TransactionCard(
              transaction: item,
              onDelete: () {
                _showDeleteConfirm(context, item.id);
              },
            ),
          )
          .toList(),
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
