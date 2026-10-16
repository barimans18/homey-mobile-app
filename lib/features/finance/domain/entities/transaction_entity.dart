import 'package:equatable/equatable.dart';

/// Entity Transaksi Kas Bersama (Joint Ledger)
class TransactionEntity extends Equatable {
  final String id;
  final String familyId;
  final String userId;
  final String type; // 'expense' atau 'income'
  final double amount;
  final String category;
  final String title;
  final String? notes;
  final DateTime transactionDate;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.title,
    this.notes,
    required this.transactionDate,
    required this.createdAt,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  TransactionEntity copyWith({
    String? id,
    String? familyId,
    String? userId,
    String? type,
    double? amount,
    String? category,
    String? title,
    String? notes,
    DateTime? transactionDate,
    DateTime? createdAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        userId,
        type,
        amount,
        category,
        title,
        notes,
        transactionDate,
        createdAt,
      ];
}
