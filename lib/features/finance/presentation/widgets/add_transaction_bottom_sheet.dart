import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../domain/entities/transaction_entity.dart';
import '../cubit/finance_cubit.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final String familyId;
  final String userId;

  const AddTransactionBottomSheet({
    super.key,
    required this.familyId,
    required this.userId,
  });

  static Future<void> show(
    BuildContext context, {
    required String familyId,
    required String userId,
  }) {
    final financeCubit = context.read<FinanceCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: financeCubit,
        child: AddTransactionBottomSheet(
          familyId: familyId,
          userId: userId,
        ),
      ),
    );
  }

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'expense'; // 'expense' atau 'income'
  String _selectedCategory = 'Dapur & Makanan';
  bool _isLoading = false;

  final List<String> _expenseCategories = [
    'Dapur & Makanan',
    'Tagihan & Utilitas',
    'Kebutuhan Anak',
    'Belanja Rumah',
    'Transportasi',
    'Hiburan & Rekreasi',
    'Kesehatan',
    'Lainnya',
  ];

  final List<String> _incomeCategories = [
    'Gaji & Pendapatan',
    'Bonus & Tunjangan',
    'Bisnis Bersama',
    'Investasi',
    'Lainnya',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    setState(() {
      _type = newType;
      _selectedCategory = newType == 'expense'
          ? _expenseCategories.first
          : _incomeCategories.first;
    });
  }

  Future<void> _submitTransaction() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText);

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan judul transaksi'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal harus lebih besar dari 0'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final newTransaction = TransactionEntity(
      id: const Uuid().v4(),
      familyId: widget.familyId,
      userId: widget.userId,
      type: _type,
      amount: amount,
      category: _selectedCategory,
      title: title,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      transactionDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await context.read<FinanceCubit>().addTransaction(newTransaction);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == 'expense'
                ? 'Pengeluaran berhasil dicatat!'
                : 'Pemasukan berhasil dicatat!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentCategories =
        _type == 'expense' ? _expenseCategories : _incomeCategories;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.bottomSheetRadius,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Catat Transaksi Kas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type Segmented Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      label: 'Pengeluaran',
                      typeValue: 'expense',
                      color: AppColors.accentTerracotta,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildTypeButton(
                      label: 'Pemasukan',
                      typeValue: 'income',
                      color: AppColors.accentGreen,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nominal Input
            Text(
              'Nominal (Rp)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                hintText: '0',
              ),
            ),
            const SizedBox(height: 18),

            // Judul Transaksi
            Text(
              'Judul Transaksi',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: _type == 'expense'
                    ? 'Misal: Belanja Sayur & Daging'
                    : 'Misal: Gaji Bulanan Masuk',
                prefixIcon: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Kategori Chips
            Text(
              'Kategori',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentCategories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: _type == 'expense'
                      ? AppColors.accentTerracotta.withValues(alpha: 0.18)
                      : AppColors.accentGreen.withValues(alpha: 0.18),
                  backgroundColor: AppColors.background,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (_type == 'expense'
                            ? AppColors.accentTerracotta
                            : AppColors.accentGreen)
                        : AppColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? (_type == 'expense'
                            ? AppColors.accentTerracotta
                            : AppColors.accentGreen)
                        : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Catatan Opsional
            Text(
              'Catatan Tambahan (Opsional)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Tulis keterangan tambahan...',
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            PrimaryButton(
              text: 'Simpan ke Kas Bersama',
              isLoading: _isLoading,
              icon: Icons.check_circle_rounded,
              onPressed: _submitTransaction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required String typeValue,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _type == typeValue;

    return GestureDetector(
      onTap: () => _onTypeChanged(typeValue),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
