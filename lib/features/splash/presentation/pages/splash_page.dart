import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/session_storage_service.dart';

/// Halaman Splash dengan animasi transisi 2 detik
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Animasi Scale lembut dengan pantulan halus
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Animasi Fade In cepat agar tidak ada jeda kosong
    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Animasi Slide Up untuk teks branding
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Jalankan animasi 2 detik lalu berpindah sesuai sesi local storage
    _controller.forward().then((_) {
      if (mounted) {
        final sessionStorage = sl<SessionStorageService>();
        if (sessionStorage.isLoggedIn()) {
          context.go(AppRouter.home);
        } else {
          context.go(AppRouter.login);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Logo Icon dengan Scale Animation
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadii.outerContainerRadius,
                          boxShadow: AppShadows.soft,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background icon shape
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.accentTerracotta.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            // House icon
                            const Icon(
                              Icons.cottage_rounded,
                              size: 52,
                              color: AppColors.accentTerracotta,
                            ),
                            // Small decorative love badge
                            Positioned(
                              top: 26,
                              right: 26,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.accentGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Teks Branding dengan Slide Animation
                    SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Homey',
                            style: GoogleFonts.nunito(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ruang kolaborasi hangat untuk berdua',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Indikator loading halus di bagian bawah
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final delay = index * 0.2;
                          final progress = ((_controller.value - delay) * 2).clamp(0.0, 1.0);
                          final scale = 0.8 + (progress * 0.4);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8 * scale,
                            height: 8 * scale,
                            decoration: BoxDecoration(
                              color: index == 1
                                  ? AppColors.accentTerracotta
                                  : (index == 0 ? AppColors.accentGreen : AppColors.accentYellow),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
