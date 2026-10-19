import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/presentation/widgets/custom_app_bar.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/session_storage_service.dart';
import '../../domain/entities/user_role.dart';
import '../cubit/family_cubit.dart';
import '../cubit/family_state.dart';
import '../cubit/role_selection_cubit.dart';
import '../cubit/role_selection_state.dart';
import '../widgets/role_card.dart';

/// Halaman Onboarding & Setup Keluarga (Sesuai PRD: Role Selection & Family Pairing)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController(text: 'Demo Pasutri');
  final _familyNameController = TextEditingController(text: 'Keluarga Bahagia');
  final _createPinController = TextEditingController(text: '123456');
  final _inviteCodeController = TextEditingController();
  final _joinPinController = TextEditingController();
  
  // Tab 0: Buat Rumah Baru, Tab 1: Gabung Rumah Pasangan
  int _selectedFamilyTab = 0;
  bool _obscureCreatePin = false;
  bool _obscureJoinPin = true;
  bool _showEmailLogin = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _familyNameController.dispose();
    _createPinController.dispose();
    _inviteCodeController.dispose();
    _joinPinController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitOnboarding(UserRole selectedRole) {
    final name = _nameController.text.trim().isEmpty ? 'Pasutri' : _nameController.text.trim();
    final roleString = selectedRole == UserRole.husband ? 'suami' : 'istri';

    if (_selectedFamilyTab == 0) {
      // 1. Buat Rumah Baru dengan Nama Keluarga & PIN 6 Digit
      final familyName = _familyNameController.text.trim();
      if (familyName.isEmpty) {
        _showSnackBar('Silakan tentukan Nama Keluarga Anda terlebih dahulu', isError: true);
        return;
      }
      final pin = _createPinController.text.trim();
      if (pin.length != 6 || int.tryParse(pin) == null) {
        _showSnackBar('Silakan buat PIN Keluarga berupa 6 digit angka', isError: true);
        return;
      }
      context.read<FamilyCubit>().createFamily(
        familyName,
        pin: pin,
        fullName: name,
        role: roleString,
      );
    } else {
      // 2. Gabung dengan Kode Keluarga & PIN dari Pasangan
      final code = _inviteCodeController.text.trim();
      if (code.isEmpty) {
        _showSnackBar('Silakan masukkan Kode Keluarga dari pasangan Anda', isError: true);
        return;
      }
      final pin = _joinPinController.text.trim();
      if (pin.length != 6 || int.tryParse(pin) == null) {
        _showSnackBar('Silakan masukkan 6 digit PIN Keluarga dari pasangan Anda', isError: true);
        return;
      }
      context.read<FamilyCubit>().joinFamilyByCode(
        code,
        pin: pin,
        fullName: name,
        role: roleString,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppColors.error : AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.chipRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FamilyCubit, FamilyState>(
          listener: (context, state) {
            if (state is FamilyLoaded) {
              if (state.notificationMessage != null) {
                final isSuccess = state.notificationMessage!.contains('berhasil') ||
                    state.notificationMessage!.contains('Yeay');
                _showSnackBar(state.notificationMessage!, isError: !isSuccess);
                if (isSuccess) {
                  // Simpan sesi ke local storage
                  sl<SessionStorageService>().saveSession(
                    userId: state.profile.id,
                    role: state.profile.role,
                    fullName: state.profile.fullName,
                    familyId: state.family?.id,
                    familyName: state.family?.name,
                  );
                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (context.mounted) context.go('/home');
                  });
                }
              }
            } else if (state is FamilyError) {
              _showSnackBar(state.message, isError: true);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomAppBar(
          title: 'Homey 🏡',
          subtitle: 'Ruang kolaborasi hangat untuk berdua',
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang di Rumah!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cukup tentukan peran dan nama keluarga Anda untuk memulai kolaborasi.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 24),

                // 1. Pemilihan Peran
                Text(
                  '1. Pilih Peran Anda',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<RoleSelectionCubit, RoleSelectionState>(
                  builder: (context, state) {
                    final selectedRole = state is RoleSelectionLoaded
                        ? state.selectedRole ?? UserRole.husband
                        : UserRole.husband;

                    return Column(
                      children: [
                        RoleCard(
                          role: UserRole.husband,
                          isSelected: selectedRole == UserRole.husband,
                          onTap: () {
                            context.read<RoleSelectionCubit>().selectRole(UserRole.husband);
                          },
                        ),
                        const SizedBox(height: 12),
                        RoleCard(
                          role: UserRole.wife,
                          isSelected: selectedRole == UserRole.wife,
                          onTap: () {
                            context.read<RoleSelectionCubit>().selectRole(UserRole.wife);
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 2. Nama Panggilan Anda
                Text(
                  '2. Nama Panggilan Anda',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Misal: Rian, Sarah, Abi, Bunda',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.accentTerracotta),
                  ),
                ),

                const SizedBox(height: 28),

                // 3. Setup Keluarga (Segmented Bar)
                Text(
                  '3. Setup Rumah Keluarga',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadii.buttonRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFamilyTab = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedFamilyTab == 0 ? AppColors.accentTerracotta : Colors.transparent,
                              borderRadius: AppRadii.buttonRadius,
                              boxShadow: _selectedFamilyTab == 0 ? AppShadows.soft : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🏡 Buat Rumah Baru',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedFamilyTab == 0 ? Colors.white : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFamilyTab = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedFamilyTab == 1 ? AppColors.accentTerracotta : Colors.transparent,
                              borderRadius: AppRadii.buttonRadius,
                              boxShadow: _selectedFamilyTab == 1 ? AppShadows.soft : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🔗 Gabung Pasangan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedFamilyTab == 1 ? Colors.white : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tab Content
                if (_selectedFamilyTab == 0) ...[
                  // Opsi A: Buat Rumah Baru (Input Nama Keluarga & PIN 6 Digit)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadii.cardRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nama Keluarga / Rumah Tangga',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _familyNameController,
                          decoration: const InputDecoration(
                            hintText: 'Misal: Keluarga Bahagia, Rumah Rian-Sarah',
                            prefixIcon: Icon(Icons.home_work_outlined, color: AppColors.accentGreen),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Buat PIN Keluarga (6 Digit Angka)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
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
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textMuted),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'PIN ini dan kode keluarga akan dibagikan ke pasangan saat bergabung.',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Opsi B: Gabung dengan Kode Pasangan & PIN
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadii.cardRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kode Keluarga dari Pasangan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _inviteCodeController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Contoh: HOMEY-2026',
                            prefixIcon: Icon(Icons.vpn_key_rounded, color: AppColors.accentTerracotta),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'PIN Keluarga dari Pasangan (6 Digit)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
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
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textMuted),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Minta kode keluarga dan 6 digit PIN yang ada di menu Settings pasangan Anda.',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Tombol Submit Utama
                BlocBuilder<FamilyCubit, FamilyState>(
                  builder: (context, familyState) {
                    final roleState = context.watch<RoleSelectionCubit>().state;
                    final selectedRole = roleState is RoleSelectionLoaded
                        ? roleState.selectedRole ?? UserRole.husband
                        : UserRole.husband;
                    final isLoading = familyState is FamilyLoading;

                    return PrimaryButton(
                      text: _selectedFamilyTab == 0
                          ? 'Mulai & Buat Rumah Kami 🚀'
                          : 'Hubungkan ke Pasangan & Masuk 🔗',
                      isLoading: isLoading,
                      icon: _selectedFamilyTab == 0 ? Icons.cottage_rounded : Icons.link_rounded,
                      onPressed: () => _submitOnboarding(selectedRole),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Tombol Masuk Cepat / Lewati (Jika sudah pernah setup)
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final familyState = context.read<FamilyCubit>().state;
                      final sessionStorage = sl<SessionStorageService>();
                      if (familyState is FamilyLoaded) {
                        await sessionStorage.saveSession(
                          userId: familyState.profile.id,
                          role: familyState.profile.role,
                          fullName: familyState.profile.fullName,
                          familyId: familyState.family?.id,
                          familyName: familyState.family?.name,
                        );
                      } else {
                        await sessionStorage.saveSession(
                          userId: '6471baf6-3b32-4a9b-9ee2-6ada214e4eb2',
                          role: 'suami',
                          fullName: _nameController.text.trim().isEmpty ? 'Bariman' : _nameController.text.trim(),
                        );
                      }
                      if (context.mounted) context.go('/home');
                    },
                    child: const Text(
                      'Sudah terhubung sebelumnya? Masuk ke Rumah →',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentTerracotta,
                      ),
                    ),
                  ),
                ),

                // Accordion Opsional: Login dengan Email/Password
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _showEmailLogin = !_showEmailLogin),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showEmailLogin
                              ? 'Tutup Opsi Akun Email'
                              : 'Opsi Lanjutan: Masuk dengan Email & Password (Opsional)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Icon(
                          _showEmailLogin ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showEmailLogin) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.cardRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'nama@keluarga.com',
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
