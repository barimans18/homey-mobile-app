import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:homey/features/finance/domain/entities/transaction_entity.dart';
import 'package:homey/features/finance/domain/repositories/finance_repository.dart';
import 'package:homey/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:homey/features/finance/presentation/cubit/finance_state.dart';

class MockFinanceRepository extends Mock implements FinanceRepository {}

void main() {
  group('FinanceCubit Tests', () {
    late MockFinanceRepository mockRepository;
    late FinanceCubit cubit;

    final octoberTransaction = TransactionEntity(
      id: 'tx-1',
      familyId: 'family-1',
      userId: 'user-1',
      title: 'Belanja Bulanan',
      amount: 500000,
      type: 'expense',
      category: 'Dapur & Makanan',
      transactionDate: DateTime(2026, 10, 15),
      createdAt: DateTime(2026, 10, 15),
    );

    final septemberTransaction = TransactionEntity(
      id: 'tx-2',
      familyId: 'family-1',
      userId: 'user-1',
      title: 'Gaji Bulanan',
      amount: 10000000,
      type: 'income',
      category: 'Gaji',
      transactionDate: DateTime(2026, 9, 25),
      createdAt: DateTime(2026, 9, 25),
    );

    final allTransactions = [octoberTransaction, septemberTransaction];

    setUp(() {
      mockRepository = MockFinanceRepository();
      cubit = FinanceCubit(financeRepository: mockRepository);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state harus FinanceInitial', () {
      expect(cubit.state, equals(const FinanceInitial()));
    });

    blocTest<FinanceCubit, FinanceState>(
      'Emits [FinanceLoading, FinanceLoaded] saat watchFamilyTransactions berhasil',
      build: () {
        when(() => mockRepository.watchFamilyTransactions('family-1'))
            .thenAnswer((_) => Stream.value(allTransactions));
        return cubit;
      },
      act: (c) => c.watchFamilyTransactions('family-1'),
      expect: () => [
        const FinanceLoading(),
        isA<FinanceLoaded>()
            .having((s) => s.transactions.length, 'total transactions', 2),
      ],
      verify: (_) {
        verify(() => mockRepository.watchFamilyTransactions('family-1')).called(1);
      },
    );

    test('FinanceLoaded memfilter transaksi sesuai selectedMonth', () {
      final state = FinanceLoaded(
        transactions: allTransactions,
        selectedMonth: DateTime(2026, 10, 1),
      );

      expect(state.monthTransactions.length, equals(1));
      expect(state.monthTransactions.first.id, equals('tx-1'));
      expect(state.totalExpense, equals(500000.0));
      expect(state.totalIncome, equals(0.0));
      expect(state.balance, equals(-500000.0));
    });

    test('FinanceLoaded berpindah bulan saat changeMonth dipanggil', () {
      final state = FinanceLoaded(
        transactions: allTransactions,
        selectedMonth: DateTime(2026, 10, 1),
      );

      // Simulasikan state loaded awal
      cubit.emit(state);

      // Mundur 1 bulan ke September 2026
      cubit.changeMonth(-1);

      final newState = cubit.state as FinanceLoaded;
      expect(newState.selectedMonth.year, equals(2026));
      expect(newState.selectedMonth.month, equals(9));
      expect(newState.monthTransactions.length, equals(1));
      expect(newState.monthTransactions.first.id, equals('tx-2'));
      expect(newState.totalIncome, equals(10000000.0));
      expect(newState.totalExpense, equals(0.0));
      expect(newState.balance, equals(10000000.0));
    });
  });
}
