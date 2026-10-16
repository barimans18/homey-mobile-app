import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionCard extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Dapur & Makanan':
        return Icons.restaurant_rounded;
      case 'Tagihan & Utilitas':
        return Icons.bolt_rounded;
      case 'Kebutuhan Anak':
        return Icons.child_care_rounded;
      case 'Belanja Rumah':
        return Icons.shopping_bag_rounded;
      case 'Transportasi':
        return Icons.directions_car_rounded;
      case 'Hiburan & Rekreasi':
        return Icons.movie_rounded;
      case 'Gaji & Pendapatan':
        return Icons.payments_rounded;
      case 'Bonus & Tunjangan':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final isExpense = transaction.isExpense;
    final amountPrefix = isExpense ? '-' : '+';
    final amountColor = isExpense ? AppColors.accentTerracotta : AppColors.accentGreen;
    final iconColor = isExpense ? AppColors.accentTerracotta : AppColors.accentGreen;

    String dateText;
    try {
      dateText = DateFormat('d MMM yyyy', 'id_ID').format(transaction.transactionDate);
    } catch (_) {
      dateText = DateFormat('d MMM yyyy').format(transaction.transactionDate);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getCategoryIcon(transaction.category),
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        transaction.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(width: 4),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount & Delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix${currencyFormatter.format(transaction.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
