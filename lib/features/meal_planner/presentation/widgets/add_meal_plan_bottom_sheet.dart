import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/presentation/responsive/adaptive_dialog.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../../../core/utils/image_compress_util.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../cubit/meal_plan_cubit.dart';

class AddMealPlanBottomSheet extends StatefulWidget {
  final String familyId;
  final String userId;
  final DateTime initialDate;
  final MealPlanEntity? existingMealPlan;
  final MealType? initialMealType;

  const AddMealPlanBottomSheet({
    super.key,
    required this.familyId,
    required this.userId,
    required this.initialDate,
    this.existingMealPlan,
    this.initialMealType,
  });

  static Future<void> show(
    BuildContext context, {
    required String familyId,
    required String userId,
    required DateTime initialDate,
    MealPlanEntity? existingMealPlan,
    MealType? initialMealType,
  }) {
    final cubit = context.read<MealPlanCubit>();
    return AdaptiveModal.show(
      context: context,
      maxWidth: 560,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: AddMealPlanBottomSheet(
          familyId: familyId,
          userId: userId,
          initialDate: initialDate,
          existingMealPlan: existingMealPlan,
          initialMealType: initialMealType,
        ),
      ),
    );
  }

  @override
  State<AddMealPlanBottomSheet> createState() => _AddMealPlanBottomSheetState();
}

class _AddMealPlanBottomSheetState extends State<AddMealPlanBottomSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _ingredientController = TextEditingController();

  MealType _selectedType = MealType.dinner;
  late DateTime _selectedDate;
  final List<MealIngredient> _ingredients = [];

  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;
  String? _compressedSizeLabel;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingMealPlan != null) {
      final meal = widget.existingMealPlan!;
      _titleController.text = meal.title;
      _notesController.text = meal.notes ?? '';
      _selectedType = meal.mealType;
      _selectedDate = meal.planDate;
      _existingImageUrl = meal.imageUrl;
      _ingredients.addAll(meal.ingredients);
    } else {
      _selectedDate = widget.initialDate;
      if (widget.initialMealType != null) {
        _selectedType = widget.initialMealType!;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _ingredients.add(MealIngredient(name: text, isChecked: false));
      _ingredientController.clear();
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _toggleIngredient(int index, bool? val) {
    setState(() {
      _ingredients[index] = _ingredients[index].copyWith(isChecked: val ?? false);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      final rawBytes = await picked.readAsBytes();
      // Kompresi foto dengan ImageCompressUtil (bytes)
      final compressedResult = await ImageCompressUtil.compressImageBytes(
        rawBytes,
        fileName: picked.name,
        maxDimension: 1200,
        quality: 85,
      );

      setState(() {
        _selectedImageBytes = compressedResult.bytes;
        _compressedSizeLabel = compressedResult.compressedSizeFormatted;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.bottomSheetRadius),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Foto Masakan',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.accentTerracotta),
                title: const Text('Kamera', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.accentGreen),
                title: const Text('Galeri Foto', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan nama menu makanan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cubit = context.read<MealPlanCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isLoading = true);

    try {
      final mealId = widget.existingMealPlan?.id ?? const Uuid().v4();
      String? finalImageUrl = _existingImageUrl;

      // Upload foto jika pengguna memilih foto baru
      if (_selectedImageBytes != null) {
        final fileName = 'meal_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadedUrl = await cubit.uploadMealPhoto(
              mealId: mealId,
              imageBytes: _selectedImageBytes!,
              fileName: fileName,
            );
        finalImageUrl = uploadedUrl;
      }

      final mealPlan = MealPlanEntity(
        id: mealId,
        familyId: widget.familyId,
        createdBy: widget.userId,
        planDate: _selectedDate,
        mealType: _selectedType,
        title: title,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ingredients: _ingredients,
        imageUrl: finalImageUrl,
        isSyncedToGrocery: widget.existingMealPlan?.isSyncedToGrocery ?? false,
      );

      if (widget.existingMealPlan != null) {
        await cubit.updateMealPlan(mealPlan);
      } else {
        await cubit.addMealPlan(mealPlan);
      }

      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.existingMealPlan != null
                  ? 'Menu "${mealPlan.title}" berhasil diperbarui! 🍲'
                  : 'Menu ${_selectedType.label} berhasil disimpan! 🍽️',
            ),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan menu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate);
    final isEdit = widget.existingMealPlan != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.bottomSheetRadius,
      ),
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
                isEdit ? 'Edit Menu Makan 🍽️' : 'Rencana Menu Makan 🍽️',
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
            'Rencanakan menu lezat untuk $dateStr',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Upload Foto Masakan (Kamera / Galeri dengan Kompresi)
                  const Text(
                    'Foto Masakan (Opsional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_selectedImageBytes != null) ...[
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: AppRadii.cardRadius,
                          child: Image.memory(
                            _selectedImageBytes!,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _selectedImageBytes = null;
                                  _compressedSizeLabel = null;
                                });
                              },
                            ),
                          ),
                        ),
                        if (_compressedSizeLabel != null)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Terkonversi: $_compressedSizeLabel',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppColors.accentTerracotta),
                      icon: const Icon(Icons.photo_camera_rounded, size: 16),
                      label: const Text('Ganti Foto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      onPressed: _showImagePickerModal,
                    ),
                  ] else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) ...[
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: AppRadii.cardRadius,
                          child: Image.network(
                            _existingImageUrl!,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _existingImageUrl = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppColors.accentTerracotta),
                      icon: const Icon(Icons.photo_camera_rounded, size: 16),
                      label: const Text('Ganti Foto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      onPressed: _showImagePickerModal,
                    ),
                  ] else ...[
                    InkWell(
                      borderRadius: AppRadii.cardRadius,
                      onTap: _showImagePickerModal,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: AppRadii.cardRadius,
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.accentTerracotta),
                            SizedBox(height: 8),
                            Text(
                              'Unggah Foto (Kamera / Galeri)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Otomatis dikompres agar hemat penyimpanan & cepat dimuat',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // 2. Pilihan Waktu Makan (Sarapan, Siang, Malam)
                  const Text(
                    'Waktu Makan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: MealType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
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
                              type.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // 3. Nama Menu
                  const Text(
                    'Nama Menu / Masakan',
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
                      hintText: 'Misal: Ayam Bakar Madu & Sambal Bajak',
                      prefixIcon: Icon(Icons.restaurant_rounded, color: AppColors.accentTerracotta),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Bahan Makanan (Multi Checkbox + Tambah + Delete)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daftar Bahan Makanan 🛒',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_ingredients.length} item',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Input tambah bahan
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ingredientController,
                          decoration: InputDecoration(
                            hintText: 'Tambah bahan (cth: Ayam 1 ekor, Madu)',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            prefixIcon: const Icon(Icons.egg_alt_outlined, color: AppColors.accentGreen, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add_circle_rounded, color: AppColors.accentTerracotta),
                              onPressed: _addIngredient,
                            ),
                          ),
                          onSubmitted: (_) => _addIngredient(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // List Bahan dengan Checkbox & Tombol Hapus
                  if (_ingredients.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ingredients.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final item = _ingredients[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.isChecked,
                                  activeColor: AppColors.accentGreen,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  onChanged: (val) => _toggleIngredient(index, val),
                                ),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: item.isChecked ? AppColors.textMuted : AppColors.textPrimary,
                                      decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                  tooltip: 'Hapus Bahan',
                                  onPressed: () => _removeIngredient(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 5. Catatan / Resep (Free Text)
                  const Text(
                    'Catatan / Resep Masakan (Free Text)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Tuliskan instruksi memasak, tips rasa, atau catatan belanja keluarga...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.notes_rounded, color: AppColors.accentTerracotta),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          PrimaryButton(
            text: isEdit ? 'Perbarui Menu Makanan 🍲' : 'Simpan Rencana Menu 🍲',
            isLoading: _isLoading,
            icon: Icons.check_circle_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
