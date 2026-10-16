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

  const FinanceLoaded({
    required this.transactions,
    this.activeFilter = 'all',
  });

  double get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpense => transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get balance => totalIncome - totalExpense;

  Map<String, double> get expensesByCategory {
    final Map<String, double> result = {};
    for (final t in transactions.where((t) => t.isExpense)) {
      result[t.category] = (result[t.category] ?? 0.0) + t.amount;
    }
    return result;
  }

  List<TransactionEntity> get filteredTransactions {
    if (activeFilter == 'expense') {
      return transactions.where((t) => t.isExpense).toList();
    } else if (activeFilter == 'income') {
      return transactions.where((t) => t.isIncome).toList();
    }
    return transactions;
  }

  FinanceLoaded copyWith({
    List<TransactionEntity>? transactions,
    String? activeFilter,
  }) {
    return FinanceLoaded(
      transactions: transactions ?? this.transactions,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  @override
  List<Object?> get props => [transactions, activeFilter];
}

class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}
