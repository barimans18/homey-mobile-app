import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../../meal_planner/presentation/cubit/meal_plan_cubit.dart';
import '../../../meal_planner/presentation/cubit/meal_plan_state.dart';

/// Widget Menu Makan Keluarga di Dashboard dengan Image Carousel Slider dan Empty State menarik
class MealPlanCarouselSection extends StatefulWidget {
  final VoidCallback onSeeAllPressed;

  const MealPlanCarouselSection({
    super.key,
    required this.onSeeAllPressed,
  });

  @override
  State<MealPlanCarouselSection> createState() => _MealPlanCarouselSectionState();
}

class _MealPlanCarouselSectionState extends State<MealPlanCarouselSection> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealPlanCubit, MealPlanState>(
      builder: (context, state) {
        if (state is MealPlanLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                color: AppColors.accentTerracotta,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        final now = DateTime.now();
        List<MealPlanEntity> todayMeals = [];

        if (state is MealPlanLoaded) {
          todayMeals = state.mealPlans.where((m) {
            return m.planDate.year == now.year &&
                m.planDate.month == now.month &&
                m.planDate.day == now.day;
          }).toList();

          // Urutkan berdasarkan waktu makan: Sarapan -> Makan Siang -> Makan Malam
          todayMeals.sort((a, b) {
            final order = {
              MealType.breakfast: 0,
              MealType.lunch: 1,
              MealType.dinner: 2,
            };
            return (order[a.mealType] ?? 0).compareTo(order[b.mealType] ?? 0);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      'Menu Makan Keluarga',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: 6),
                    const Text('🍲', style: TextStyle(fontSize: 18)),
                  ],
                ),
                GestureDetector(
                  onTap: widget.onSeeAllPressed,
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentTerracotta,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Konten: Carousel jika ada data, atau Banner menarik jika kosong
            if (todayMeals.isEmpty)
              _buildEmptyStateBanner(context)
            else
              _buildCarouselSlider(context, todayMeals),
          ],
        );
      },
    );
  }

  // 1. UI Menarik jika belum ada menu makan hari ini
  Widget _buildEmptyStateBanner(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSeeAllPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AppColors.accentYellow.withValues(alpha: 0.18),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadii.cardRadius,
          border: Border.all(
            color: AppColors.accentTerracotta.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // Ilustrasi Ikon Masakan Hangat
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accentTerracotta.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentTerracotta.withValues(alpha: 0.25),
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                '🍳',
                style: TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 16),

            // Teks ajakan & CTA Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Belum Ada Menu Hari Ini',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Rencanakan masakan lezat favorit pasangan & keluarga tercinta!',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accentTerracotta,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: AppShadows.soft,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'Buat Rencana Menu ➔',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Image Carousel Slider
  Widget _buildCarouselSlider(BuildContext context, List<MealPlanEntity> meals) {
    return Column(
      children: [
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _pageController,
            itemCount: meals.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final meal = meals[index];
              return _buildCarouselItem(context, meal);
            },
          ),
        ),
        if (meals.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(meals.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: isActive ? 22 : 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accentTerracotta : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildCarouselItem(BuildContext context, MealPlanEntity meal) {
    final hasImage = meal.imageUrl != null && meal.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: widget.onSeeAllPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.cardRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gambar Masakan atau Background Pattern Estetik
              if (hasImage)
                Image.network(
                  meal.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallbackBackground(meal),
                )
              else
                _buildFallbackBackground(meal),

              // Gradient Overlay Gelap agar Teks Terbaca Jelas & Mewah
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // Badges di Bagian Atas
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge Waktu Makan (Sarapan, Siang, Malam)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        meal.mealType.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // Badge Bahan jika ada
                    if (meal.ingredients.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentTerracotta.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${meal.ingredients.length} Bahan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Konten Teks di Bagian Bawah
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meal.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meal.notes!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBackground(MealPlanEntity meal) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentTerracotta.withValues(alpha: 0.7),
            AppColors.accentTerracotta,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: Colors.white.withValues(alpha: 0.25),
          size: 72,
        ),
      ),
    );
  }
}
