import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../cubit/family_cubit.dart';
import '../cubit/family_state.dart';

class FamilyPairingDialog extends StatefulWidget {
  const FamilyPairingDialog({super.key});

  static Future<void> show(BuildContext context) {
    final familyCubit = context.read<FamilyCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: familyCubit,
        child: const FamilyPairingDialog(),
      ),
    );
  }

  @override
  State<FamilyPairingDialog> createState() => _FamilyPairingDialogState();
}

class _FamilyPairingDialogState extends State<FamilyPairingDialog> {
  final _codeController = TextEditingController();
  final _joinPinController = TextEditingController();
  final _nameController = TextEditingController();
  final _createPinController = TextEditingController(text: '123456');
  bool _isCreatingNew = false;
  bool _obscureJoinPin = true;
  bool _obscureCreatePin = false;

  @override
  void dispose() {
    _codeController.dispose();
    _joinPinController.dispose();
    _nameController.dispose();
    _createPinController.dispose();
    super.dispose();
  }

  void _onJoinPressed() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan Kode Keluarga terlebih dahulu'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final pin = _joinPinController.text.trim();
    if (pin.length != 6 || int.tryParse(pin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan 6 digit PIN keluarga dari pasangan Anda'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final familyState = context.read<FamilyCubit>().state;
    String? role;
    String? name;
    if (familyState is FamilyLoaded) {
      role = familyState.profile.role;
      name = familyState.profile.fullName;
    }
    context.read<FamilyCubit>().joinFamilyByCode(
          code,
          pin: pin,
          role: role,
          fullName: name,
        );
  }

  void _onCreatePressed() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tentukan nama keluarga Anda'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final pin = _createPinController.text.trim();
    if (pin.length != 6 || int.tryParse(pin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan buat 6 digit PIN keluarga berupa angka'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final familyState = context.read<FamilyCubit>().state;
    String? role;
    String? fullName;
    if (familyState is FamilyLoaded) {
      role = familyState.profile.role;
      fullName = familyState.profile.fullName;
    }
    context.read<FamilyCubit>().createFamily(
          name,
          pin: pin,
          role: role,
          fullName: fullName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocConsumer<FamilyCubit, FamilyState>(
      listener: (context, state) {
        if (state is FamilyLoaded && state.notificationMessage != null) {
          final isSuccess = state.notificationMessage!.contains('Berhasil') ||
              state.notificationMessage!.contains('Yeay');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.notificationMessage!),
              backgroundColor: isSuccess ? AppColors.accentGreen : AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (isSuccess) {
            Navigator.pop(context);
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is FamilyLoaded && state.isPairingLoading;

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

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _isCreatingNew
                            ? 'Buat Keluarga Baru 🏡'
                            : 'Hubungkan dengan Pasangan 🔗',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isCreatingNew
                      ? 'Buat grup keluarga Anda dan bagikan kode uniknya ke Suami/Istri.'
                      : 'Masukkan Kode Keluarga yang dibagikan oleh pasangan Anda untuk saling sinkronisasi.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Form Content
                if (!_isCreatingNew) ...[
                  Text(
                    'Kode Keluarga (Contoh: HOMEY-2026)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'HOMEY-XXXX',
                      prefixIcon: Icon(
                        Icons.vpn_key_rounded,
                        color: AppColors.accentTerracotta,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PIN Keluarga dari Pasangan (6 Digit)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _joinPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: _obscureJoinPin,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Masukkan 6 digit PIN',
                      counterText: '',
                      prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.accentTerracotta),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureJoinPin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscureJoinPin = !_obscureJoinPin),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Hubungkan ke Pasangan',
                    isLoading: isLoading,
                    icon: Icons.link_rounded,
                    onPressed: _onJoinPressed,
                  ),
                ] else ...[
                  Text(
                    'Nama Keluarga Anda',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Misal: Keluarga Bahagia',
                      prefixIcon: Icon(
                        Icons.home_rounded,
                        color: AppColors.accentGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Buat PIN Keluarga (6 Digit)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _createPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: _obscureCreatePin,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                    decoration: InputDecoration(
                      hintText: '123456',
                      counterText: '',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.accentTerracotta),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCreatePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscureCreatePin = !_obscureCreatePin),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Buat & Dapatkan Kode Unik',
                    isLoading: isLoading,
                    icon: Icons.add_home_rounded,
                    onPressed: _onCreatePressed,
                  ),
                ],

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isCreatingNew = !_isCreatingNew;
                      });
                    },
                    child: Text(
                      _isCreatingNew
                          ? 'Sudah punya kode? Gabung ke keluarga pasangan'
                          : 'Belum punya kode? Buat keluarga baru di sini',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentTerracotta,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
