import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';

class BudgetProgressCard extends StatelessWidget {
  final Map<String, double> categoryExpenses;
  final double totalExpense;

  const BudgetProgressCard({
    super.key,
    required this.categoryExpenses,
    required this.totalExpense,
  });

  // Target budget referensi per kategori
  static const Map<String, double> defaultLimits = {
    'Dapur & Makanan': 2500000,
    'Tagihan & Utilitas': 1500000,
    'Kebutuhan Anak': 2000000,
    'Belanja Rumah': 1000000,
    'Transportasi': 800000,
    'Hiburan & Rekreasi': 750000,
    'Kesehatan': 600000,
    'Lainnya': 500000,
  };

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final entries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardRadius,
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentTerracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pie_chart_rounded,
                      color: AppColors.accentTerracotta,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Budget per Kategori',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              Text(
                'Total: ${currencyFormatter.format(totalExpense)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentTerracotta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'Belum ada pengeluaran yang tercatat bulan ini.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ...entries.take(4).map((entry) {
              final limit = defaultLimits[entry.key] ?? 1000000;
              final progress = (entry.value / limit).clamp(0.0, 1.0);
              final isOverBudget = entry.value > limit;

              Color progressColor = AppColors.accentGreen;
              if (progress > 0.8) {
                progressColor = AppColors.accentTerracotta;
              } else if (progress > 0.5) {
                progressColor = AppColors.accentYellow;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${currencyFormatter.format(entry.value)} / ${currencyFormatter.format(limit)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOverBudget ? AppColors.error : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
