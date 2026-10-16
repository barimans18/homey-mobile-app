import '../../domain/entities/transaction_entity.dart';

/// Data Model untuk tabel `transactions` di Supabase
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.familyId,
    required super.userId,
    required super.type,
    required super.amount,
    required super.category,
    required super.title,
    super.notes,
    required super.transactionDate,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount'].toString()) ?? 0.0,
      category: json['category'] as String? ?? 'Umum',
      title: json['title'] as String,
      notes: json['notes'] as String?,
      transactionDate: json['transaction_date'] != null
          ? DateTime.tryParse(json['transaction_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'category': category,
      'title': title,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'transaction_date':
          '${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}',
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      familyId: entity.familyId,
      userId: entity.userId,
      type: entity.type,
      amount: entity.amount,
      category: entity.category,
      title: entity.title,
      notes: entity.notes,
      transactionDate: entity.transactionDate,
      createdAt: entity.createdAt,
    );
  }
}
