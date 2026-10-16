import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/task_cubit.dart';

class AddTaskBottomSheet extends StatefulWidget {
  final String familyId;
  final String userId;
  final DateTime initialDueDate;

  const AddTaskBottomSheet({
    super.key,
    required this.familyId,
    required this.userId,
    required this.initialDueDate,
  });

  static Future<void> show(
    BuildContext context, {
    required String familyId,
    required String userId,
    required DateTime initialDueDate,
  }) {
    final taskCubit = context.read<TaskCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: taskCubit,
        child: AddTaskBottomSheet(
          familyId: familyId,
          userId: userId,
          initialDueDate: initialDueDate,
        ),
      ),
    );
  }

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _assignee = 'both'; // 'suami', 'istri', 'both'
  late DateTime _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.initialDueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan judul tugas/agenda'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final task = TaskEntity(
      id: const Uuid().v4(),
      familyId: widget.familyId,
      createdBy: widget.userId,
      title: title,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      assignee: _assignee,
      dueDate: _dueDate,
      createdAt: DateTime.now(),
      isCompleted: false,
    );

    await context.read<TaskCubit>().addTask(task);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas berhasil ditambahkan & disinkronkan! ✨'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateStr = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_dueDate);

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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tambah Tugas Bersama 📝',
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
            Text(
              'Tenggat: $dateStr',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Judul Tugas
            const Text(
              'Judul Tugas / Agenda',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Misal: Beli Popok & Susu Anak',
                prefixIcon: Icon(Icons.task_alt_rounded, color: AppColors.accentTerracotta),
              ),
            ),
            const SizedBox(height: 16),

            // Keterangan / Lokasi
            const Text(
              'Keterangan / Lokasi (Opsional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Misal: Belanja Pulang Kerja di Minimarket',
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.accentGreen),
              ),
            ),
            const SizedBox(height: 18),

            // Penanggung Jawab (Assignee)
            const Text(
              'Ditugaskan Kepada (Assignee)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildAssigneeOption(value: 'suami', label: 'Suami 👨'),
                const SizedBox(width: 8),
                _buildAssigneeOption(value: 'istri', label: 'Istri 👩'),
                const SizedBox(width: 8),
                _buildAssigneeOption(value: 'both', label: 'Keduanya 👨‍👩‍👧'),
              ],
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              text: 'Simpan Tugas & Sinkronkan 🚀',
              isLoading: _isLoading,
              icon: Icons.check_circle_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssigneeOption({required String value, required String label}) {
    final isSelected = _assignee == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _assignee = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentTerracotta : AppColors.surface,
            borderRadius: AppRadii.chipRadius,
            border: Border.all(
              color: isSelected ? AppColors.accentTerracotta : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
