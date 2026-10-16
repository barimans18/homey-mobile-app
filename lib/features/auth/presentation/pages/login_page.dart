import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/presentation/widgets/custom_app_bar.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../domain/entities/user_role.dart';
import '../cubit/role_selection_cubit.dart';
import '../cubit/role_selection_state.dart';
import '../widgets/role_card.dart';

/// Halaman Login dengan pemilihan peran Suami / Istri
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Homey 🏡',
        subtitle: 'Ruang kolaborasi hangat untuk berdua',
      ),
      body: BlocListener<RoleSelectionCubit, RoleSelectionState>(
        listener: (context, state) {
          if (state is RoleSelectionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: AppRadii.chipRadius),
              ),
            );
          } else if (state is RoleSelectionLoaded && state.isConfirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Peran ${state.selectedRole?.label} berhasil dipilih! Masuk ke rumah...',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.accentGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: AppRadii.chipRadius),
                duration: const Duration(seconds: 1),
              ),
            );
            // Navigasi ke Dashboard Homey
            context.go('/home');
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Selamat Datang di Rumah!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Silakan pilih peran Anda dalam keluarga untuk memulai sinkronisasi.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 24),

                // Bagian Pemilihan Peran
                Text(
                  'Pilih Peran Anda',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),

                BlocBuilder<RoleSelectionCubit, RoleSelectionState>(
                  builder: (context, state) {
                    final selectedRole = state is RoleSelectionLoaded ? state.selectedRole : null;

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

                const SizedBox(height: 28),

                // Form Login Kredensial
                Text(
                  'Informasi Akun',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'nama@keluarga.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 14),
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
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Submit
                BlocBuilder<RoleSelectionCubit, RoleSelectionState>(
                  builder: (context, state) {
                    final isLoading = state is RoleSelectionLoading;

                    return PrimaryButton(
                      text: 'Masuk ke Rumah Kami',
                      isLoading: isLoading,
                      icon: Icons.login_rounded,
                      onPressed: () {
                        // Memanggil cubit tanpa mencampur business logic di file UI
                        context.read<RoleSelectionCubit>().confirmRole();
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
