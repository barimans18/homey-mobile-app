import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_remote_data_source.dart';
import '../models/transaction_model.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceRemoteDataSource _remoteDataSource;

  FinanceRepositoryImpl({required FinanceRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<TransactionEntity>> watchFamilyTransactions(String familyId) {
    return _remoteDataSource.watchFamilyTransactions(familyId);
  }

  @override
  Future<List<TransactionEntity>> getFamilyTransactions(String familyId) {
    return _remoteDataSource.getFamilyTransactions(familyId);
  }

  @override
  Future<void> createTransaction(TransactionEntity transaction) {
    final model = TransactionModel.fromEntity(transaction);
    return _remoteDataSource.createTransaction(model);
  }

  @override
  Future<void> deleteTransaction(String transactionId) {
    return _remoteDataSource.deleteTransaction(transactionId);
  }
}
