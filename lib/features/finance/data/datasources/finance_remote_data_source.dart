import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

abstract class FinanceRemoteDataSource {
  Stream<List<TransactionModel>> watchFamilyTransactions(String familyId);
  Future<List<TransactionModel>> getFamilyTransactions(String familyId);
  Future<void> createTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String transactionId);
}

class FinanceRemoteDataSourceImpl implements FinanceRemoteDataSource {
  final SupabaseClient _client;

  FinanceRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<TransactionModel>> watchFamilyTransactions(String familyId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('transaction_date', ascending: false)
        .map((data) => data.map((json) => TransactionModel.fromJson(json)).toList());
  }

  @override
  Future<List<TransactionModel>> getFamilyTransactions(String familyId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('family_id', familyId)
        .order('transaction_date', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createTransaction(TransactionModel transaction) async {
    await _client.from('transactions').insert(transaction.toJson());
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _client.from('transactions').delete().eq('id', transactionId);
  }
}
