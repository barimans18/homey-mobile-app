import '../entities/transaction_entity.dart';

abstract class FinanceRepository {
  Stream<List<TransactionEntity>> watchFamilyTransactions(String familyId);
  Future<List<TransactionEntity>> getFamilyTransactions(String familyId);
  Future<void> createTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String transactionId);
}
