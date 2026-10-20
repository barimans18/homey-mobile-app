import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/presentation/widgets/custom_app_bar.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../../../core/utils/image_compress_util.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../cubit/meal_plan_cubit.dart';

/// Halaman form tambah & edit Menu Makan Keluarga
class AddEditMealPlanPage extends StatefulWidget {
  final String familyId;
  final String userId;
  final DateTime initialDate;
  final MealPlanEntity? existingMealPlan;
  final MealType? initialMealType;

  const AddEditMealPlanPage({
    super.key,
    required this.familyId,
    required this.userId,
    required this.initialDate,
    this.existingMealPlan,
    this.initialMealType,
  });

  @override
  State<AddEditMealPlanPage> createState() => _AddEditMealPlanPageState();
}

class _AddEditMealPlanPageState extends State<AddEditMealPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _ingredientController = TextEditingController();

  MealType _selectedType = MealType.dinner;
  late DateTime _selectedDate;
  final List<MealIngredient> _ingredients = [];

  File? _selectedImageFile;
  String? _existingImageUrl;
  String? _compressedSizeLabel;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  bool get isEdit => widget.existingMealPlan != null;

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      final rawFile = File(picked.path);
      final compressedResult = await ImageCompressUtil.compressImageFile(
        rawFile,
        maxDimension: 1200,
        quality: 85,
      );

      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/compressed_meal_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(compressedResult.bytes);

      setState(() {
        _selectedImageFile = tempFile;
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
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.accentTerracotta,
                ),
                title: const Text(
                  'Kamera',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.accentGreen,
                ),
                title: const Text(
                  'Galeri Foto',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentTerracotta,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
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

      if (_selectedImageFile != null) {
        final imageBytes = await _selectedImageFile!.readAsBytes();
        final fileName = 'meal_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadedUrl = await cubit.uploadMealPhoto(
          mealId: mealId,
          imageBytes: imageBytes,
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
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        ingredients: _ingredients,
        imageUrl: finalImageUrl,
        isSyncedToGrocery: widget.existingMealPlan?.isSyncedToGrocery ?? false,
      );

      if (isEdit) {
        await cubit.updateMealPlan(mealPlan);
      } else {
        await cubit.addMealPlan(mealPlan);
      }

      if (mounted) {
        navigator.pop(true);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Menu makanan berhasil diperbarui! ✨'
                  : 'Menu makanan berhasil ditambahkan! 🍲',
            ),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan menu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: isEdit ? 'Edit Menu Makan 🍽️' : 'Tambah Menu Makan 🍲',
        subtitle: isEdit
            ? 'Perbarui hidangan lezat'
            : 'Rencanakan hidangan lezat pasutri',
        fontSize: 24,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Upload & Preview Foto Masakan
                _buildPhotoPickerSection(),
                const SizedBox(height: 20),

                // 2. Pemilihan Waktu Makan (Sarapan, Siang, Malam)
                const Text(
                  'Waktu Makan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: MealType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: type != MealType.values.last ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentTerracotta
                                : Colors.white,
                            borderRadius: AppRadii.cardRadius,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accentTerracotta
                                  : AppColors.border,
                            ),
                            boxShadow: isSelected ? AppShadows.soft : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 3. Tanggal Masak
                const Text(
                  'Tanggal Masak',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: AppRadii.cardRadius,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadii.cardRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.accentTerracotta,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Nama Menu Makanan
                const Text(
                  'Nama Menu Makanan *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Sop Buntut Sapi & Sambal Ijo',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.cardRadius,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.cardRadius,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.cardRadius,
                      borderSide: const BorderSide(
                        color: AppColors.accentTerracotta,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Catatan / Resep Singkat
                const Text(
                  'Catatan / Resep Singkat (Opsional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Misal: Rebus daging dulu 45 menit, kurangi garam...',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.cardRadius,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.cardRadius,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.cardRadius,
                      borderSide: const BorderSide(
                        color: AppColors.accentTerracotta,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Bahan-Bahan Masakan (Ingredients)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bahan-Bahan Belanja / Masak',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_ingredients.length} bahan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ingredientController,
                        onFieldSubmitted: (_) => _addIngredient(),
                        decoration: InputDecoration(
                          hintText: 'Tambah bahan (e.g. 500g Buntut Sapi)',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.cardRadius,
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadii.cardRadius,
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadii.cardRadius,
                            borderSide: const BorderSide(
                              color: AppColors.accentTerracotta,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _addIngredient,
                      borderRadius: AppRadii.cardRadius,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentTerracotta,
                          borderRadius: AppRadii.cardRadius,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_ingredients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadii.cardRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: List.generate(_ingredients.length, (index) {
                        final ing = _ingredients[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.fiber_manual_record,
                                size: 8,
                                color: AppColors.accentTerracotta,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ing.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                onPressed: () => _removeIngredient(index),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // 7. Tombol Simpan
                PrimaryButton(
                  text: isEdit
                      ? 'Perbarui Menu Makanan 🍲'
                      : 'Simpan Rencana Menu 🍲',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPickerSection() {
    final hasLocalImage = _selectedImageFile != null;
    final hasNetworkImage =
        _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _showImagePickerModal,
            child: Container(
              width: double.infinity,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.cardRadius,
                border: Border.all(
                  color: AppColors.accentTerracotta.withValues(alpha: 0.3),
                  width: 1.5,
                  style: (hasLocalImage || hasNetworkImage)
                      ? BorderStyle.solid
                      : BorderStyle.none,
                ),
                boxShadow: AppShadows.card,
              ),
              child: ClipRRect(
                borderRadius: AppRadii.cardRadius,
                child: hasLocalImage
                    ? Image.file(
                        _selectedImageFile!,
                        width: double.infinity,
                        height: 170,
                        fit: BoxFit.cover,
                      )
                    : hasNetworkImage
                    ? Image.network(
                        _existingImageUrl!,
                        width: double.infinity,
                        height: 170,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
          ),
          if (hasLocalImage || hasNetworkImage)
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: _showImagePickerModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _compressedSizeLabel != null
                            ? 'Ganti (${_compressedSizeLabel!})'
                            : 'Ganti Foto',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.accentYellow.withValues(alpha: 0.15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppShadows.soft,
            ),
            child: const Icon(
              Icons.add_a_photo_rounded,
              color: AppColors.accentTerracotta,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unggah Foto Masakan Lezat',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Kamera atau Galeri (Kompresi Otomatis)',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
