import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {
  const FinanceInitial();
}

class FinanceLoading extends FinanceState {
  const FinanceLoading();
}

class FinanceLoaded extends FinanceState {
  final List<TransactionEntity> transactions;
  final String activeFilter; // 'all', 'expense', 'income'
  final DateTime selectedMonth;

  FinanceLoaded({
    required this.transactions,
    this.activeFilter = 'all',
    DateTime? selectedMonth,
  }) : selectedMonth = selectedMonth ??
            DateTime(DateTime.now().year, DateTime.now().month);

  /// Daftar transaksi yang terjadi pada bulan yang dipilih
  List<TransactionEntity> get monthTransactions => transactions.where((t) {
        return t.transactionDate.year == selectedMonth.year &&
            t.transactionDate.month == selectedMonth.month;
      }).toList();

  /// Total pemasukan pada bulan yang dipilih
  double get totalIncome => monthTransactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, item) => sum + item.amount);

  /// Total pengeluaran pada bulan yang dipilih
  double get totalExpense => monthTransactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, item) => sum + item.amount);

  /// Sisa saldo kas pada bulan yang dipilih
  double get balance => totalIncome - totalExpense;

  /// Total pengeluaran per kategori pada bulan yang dipilih
  Map<String, double> get expensesByCategory {
    final Map<String, double> result = {};
    for (final t in monthTransactions.where((t) => t.isExpense)) {
      result[t.category] = (result[t.category] ?? 0.0) + t.amount;
    }
    return result;
  }

  /// Transaksi terfilter sesuai kategori dan bulan yang dipilih
  List<TransactionEntity> get filteredTransactions {
    if (activeFilter == 'expense') {
      return monthTransactions.where((t) => t.isExpense).toList();
    } else if (activeFilter == 'income') {
      return monthTransactions.where((t) => t.isIncome).toList();
    }
    return monthTransactions;
  }

  /// Menandakan apakah bulan yang dipilih adalah bulan sekarang
  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  FinanceLoaded copyWith({
    List<TransactionEntity>? transactions,
    String? activeFilter,
    DateTime? selectedMonth,
  }) {
    return FinanceLoaded(
      transactions: transactions ?? this.transactions,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }

  @override
  List<Object?> get props => [transactions, activeFilter, selectedMonth];
}

class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}
