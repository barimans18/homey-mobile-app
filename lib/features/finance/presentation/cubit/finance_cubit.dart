import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/finance_repository.dart';
import 'finance_state.dart';

class FinanceCubit extends Cubit<FinanceState> {
  final FinanceRepository _financeRepository;
  StreamSubscription<List<TransactionEntity>>? _subscription;

  FinanceCubit({required FinanceRepository financeRepository})
      : _financeRepository = financeRepository,
        super(const FinanceInitial());

  void watchFamilyTransactions(String familyId) {
    emit(const FinanceLoading());
    _subscription?.cancel();

    _subscription = _financeRepository.watchFamilyTransactions(familyId).listen(
      (transactions) {
        final currentFilter = (state is FinanceLoaded)
            ? (state as FinanceLoaded).activeFilter
            : 'all';
        emit(FinanceLoaded(
          transactions: transactions,
          activeFilter: currentFilter,
        ));
      },
      onError: (error) {
        emit(FinanceError('Gagal memuat catatan keuangan: $error'));
      },
    );
  }

  void setFilter(String filter) {
    if (state is FinanceLoaded) {
      emit((state as FinanceLoaded).copyWith(activeFilter: filter));
    }
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    final currentState = state;
    if (currentState is FinanceLoaded) {
      final updatedList = [transaction, ...currentState.transactions];
      emit(currentState.copyWith(transactions: updatedList));
    }
    try {
      await _financeRepository.createTransaction(transaction);
    } catch (e) {
      emit(currentState);
      emit(FinanceError('Gagal menyimpan transaksi: $e'));
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final currentState = state;
    if (currentState is FinanceLoaded) {
      final updatedList = currentState.transactions
          .where((t) => t.id != transactionId)
          .toList();
      emit(currentState.copyWith(transactions: updatedList));
    }
    try {
      await _financeRepository.deleteTransaction(transactionId);
    } catch (e) {
      emit(currentState);
      emit(FinanceError('Gagal menghapus transaksi: $e'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
