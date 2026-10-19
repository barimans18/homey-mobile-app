import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../../../core/utils/image_compress_util.dart';
import '../../domain/entities/family_entity.dart';
import '../cubit/family_cubit.dart';
import '../cubit/family_state.dart';

/// Modal Bottom Sheet untuk Edit Profil (Nama & Foto Profil dari Kamera/Galeri)
class EditProfileBottomSheet extends StatefulWidget {
  final UserProfileEntity profile;

  const EditProfileBottomSheet({
    super.key,
    required this.profile,
  });

  static Future<void> show(BuildContext context, {required UserProfileEntity profile}) {
    final familyCubit = context.read<FamilyCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: familyCubit,
        child: EditProfileBottomSheet(profile: profile),
      ),
    );
  }

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  late final TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();
  
  CompressedImageResult? _compressedImage;
  bool _isLoading = false;
  String? _compressionInfo;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName ?? '');
    _birthDate = widget.profile.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
      });

      // 1. Jalankan proses kompresi di background isolate tanpa mengurangi kualitas
      final compressed = await ImageCompressUtil.compressImageFile(
        File(pickedFile.path),
        maxDimension: 1024,
        quality: 85,
      );

      setState(() {
        _compressedImage = compressed;
        _isLoading = false;
        _compressionInfo =
            'Terkonversi: ${compressed.originalSizeFormatted} ➔ ${compressed.compressedSizeFormatted} '
            '(-${compressed.compressionRatioPercent.toStringAsFixed(0)}%) visual jernih';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto berhasil dikompresi: ${_compressedImage!.compressedSizeFormatted} '
              '(hemat ${_compressedImage!.compressionRatioPercent.toStringAsFixed(0)}% tanpa mengurangi kejernihan)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.accentGreen,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.bottomSheetRadius),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Sumber Foto Profil',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Foto akan dikompresi otomatis agar hemat kuota tanpa mengurangi kejernihan.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentTerracotta.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.accentTerracotta),
                ),
                title: const Text('Ambil Foto dari Kamera', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Gunakan kamera langsung', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.accentGreen),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Pilih foto dari penyimpanan galeri', style: TextStyle(fontSize: 12)),
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

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: 'PILIH TANGGAL LAHIR',
      cancelText: 'Batal',
      confirmText: 'Pilih',
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
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama panggilan tidak boleh kosong'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? avatarUrl = widget.profile.avatarUrl;

      // 1. Upload foto terkompresi jika ada foto baru
      if (_compressedImage != null) {
        final cubit = context.read<FamilyCubit>();
        final uploadedUrl = await cubit.uploadAvatar(
          imageBytes: _compressedImage!.bytes,
          fileName: _compressedImage!.fileName,
        );
        if (uploadedUrl != null) {
          avatarUrl = uploadedUrl;
        }
      }

      // 2. Simpan update profil (nama, avatarUrl & birthDate)
      if (!mounted) return;
      final cubit = context.read<FamilyCubit>();
      await cubit.updateProfile(
            fullName: newName,
            avatarUrl: avatarUrl,
            birthDate: _birthDate,
          );

      // Sinkronkan juga ke tanggal keluarga jika ada (tanpa mengubah tanggal pernikahan)
      final familyState = cubit.state;
      if (familyState is FamilyLoaded && familyState.family != null && _birthDate != null) {
        if (widget.profile.isHusband) {
          await cubit.updateFamilyDates(
            husbandBirthday: _birthDate,
            updateHusbandBirthday: true,
            updateWeddingDate: false,
            updateWifeBirthday: false,
          );
        } else {
          await cubit.updateFamilyDates(
            wifeBirthday: _birthDate,
            updateWifeBirthday: true,
            updateWeddingDate: false,
            updateHusbandBirthday: false,
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui! ✨'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isHusband = widget.profile.isHusband;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.bottomSheetRadius,
        boxShadow: AppShadows.card,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profil',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Avatar Preview & Camera Button
            GestureDetector(
              onTap: _showImageSourcePicker,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHusband
                          ? AppColors.accentTerracotta.withValues(alpha: 0.15)
                          : AppColors.accentGreen.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.accentTerracotta.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: _compressedImage != null
                          ? Image.memory(
                              _compressedImage!.bytes,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            )
                          : (widget.profile.avatarUrl != null &&
                                  widget.profile.avatarUrl!.isNotEmpty)
                              ? Image.network(
                                  widget.profile.avatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      isHusband ? '👨' : '👩',
                                      style: const TextStyle(fontSize: 48),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    isHusband ? '👨' : '👩',
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentTerracotta,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: AppShadows.soft,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _showImageSourcePicker,
              icon: const Icon(Icons.photo_camera_back_rounded, size: 16),
              label: const Text(
                'Ganti Foto Profil',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentTerracotta,
              ),
            ),

            if (_compressionInfo != null) ...[
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _compressionInfo!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 2. Input Nama Panggilan
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nama Panggilan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Misal: Rian, Sarah, Bunda, Abi',
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.accentTerracotta,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Input Tanggal Lahir / Ulang Tahun
                const Text(
                  'Tanggal Lahir / Ulang Tahun',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickBirthDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _birthDate != null
                            ? AppColors.accentTerracotta.withValues(alpha: 0.5)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cake_outlined,
                          color: AppColors.accentTerracotta,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _birthDate != null
                                ? DateFormat('d MMMM yyyy', 'id_ID').format(_birthDate!)
                                : 'Pilih tanggal lahir (Ulang tahun)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _birthDate != null ? FontWeight.w700 : FontWeight.w500,
                              color: _birthDate != null ? AppColors.textPrimary : AppColors.textMuted,
                            ),
                          ),
                        ),
                        if (_birthDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _birthDate = null),
                            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                          )
                        else
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColors.accentTerracotta,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Info Peran (Non-editable, informatif)
                const Text(
                  'Peran dalam Rumah Tangga',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isHusband ? '👨' : '👩',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isHusband ? 'Suami' : 'Istri',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Tetap',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Tombol Simpan
            PrimaryButton(
              text: _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}
