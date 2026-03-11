import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:clip_ai/core/constants/app_colors.dart';
import 'package:clip_ai/core/constants/app_strings.dart';
import 'package:clip_ai/core/di/injection.dart';
import 'package:clip_ai/domain/entities/template_entity.dart';
import 'package:clip_ai/presentation/templates/bloc/template_bloc.dart';
import 'package:clip_ai/presentation/templates/bloc/template_event.dart';
import 'package:clip_ai/presentation/templates/bloc/template_state.dart';
import 'package:clip_ai/services/analytics_service.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  static const _categories = [
    AppStrings.allCategories,
    AppStrings.trending,
    AppStrings.business,
    AppStrings.lifestyle,
    AppStrings.funny,
    AppStrings.music,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GetIt.I<TemplateBloc>()..add(TemplatesLoadRequested()),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          surfaceTintColor: Colors.transparent,
          title: Text(
            AppStrings.templates,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: false,
        ),
        body: BlocBuilder<TemplateBloc, TemplateState>(
        builder: (context, state) {
          final selectedCategory = switch (state) {
            TemplatesLoaded(selectedCategory: final c) => c,
            _ => AppStrings.allCategories,
          };

          return Column(
            children: [
              _buildCategoryChips(context, selectedCategory),
              const SizedBox(height: 8),
              Expanded(
                child: switch (state) {
                  TemplatesLoading() => _buildLoading(),
                  TemplatesLoaded() => _buildGrid(context, state),
                  TemplatesError(message: final msg) =>
                    _buildError(context, msg),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context, String selected) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final category = _categories[index];
          final isSelected = category == selected;
          return GestureDetector(
            onTap: () {
              final value =
                  category == AppStrings.allCategories ? null : category;
              context
                  .read<TemplateBloc>()
                  .add(TemplatesCategoryChanged(value));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient:
                    isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                border: isSelected
                    ? null
                    : Border.all(
                        color: AppColors.cardDark.withValues(alpha: 0.5)),
              ),
              child: Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, TemplatesLoaded state) {
    if (state.templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.video,
              size: 56,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: state.templates.length,
      itemBuilder: (context, index) => _TemplateGridCard(
        template: state.templates[index],
        isPro: state.isPro,
        onTap: () {
          final template = state.templates[index];
          if (template.isPro && !state.isPro) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.upgradeToAccess),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: SnackBarAction(
                  label: AppStrings.goPro,
                  textColor: Colors.black,
                  onPressed: () {},
                ),
              ),
            );
          } else {
            getIt<AnalyticsService>().logTemplateSelected(
              templateId: template.id,
              templateName: template.name,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening "${template.name}" in editor...'),
                backgroundColor: AppColors.surfaceDark,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => context
                  .read<TemplateBloc>()
                  .add(TemplatesLoadRequested()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                AppStrings.retry,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateGridCard extends StatelessWidget {
  final TemplateEntity template;
  final bool isPro;
  final VoidCallback onTap;

  const _TemplateGridCard({
    required this.template,
    required this.isPro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.surfaceDark.withValues(alpha: 0.6),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.accent.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Iconsax.video_play,
                        size: 40,
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  if (template.isPro && !isPro)
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: const Center(
                        child: Icon(
                          Iconsax.lock,
                          color: AppColors.proBadge,
                          size: 32,
                        ),
                      ),
                    ),
                  if (template.isPro)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.proBadgeGradientStart,
                              AppColors.proBadgeGradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PRO',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  if (template.durationSeconds != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDuration(template.durationSeconds!),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.category,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
