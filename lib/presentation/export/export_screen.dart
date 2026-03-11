import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import 'package:clip_ai/core/constants/app_colors.dart';
import 'package:clip_ai/core/constants/app_strings.dart';
import 'bloc/export_bloc.dart';
import 'bloc/export_event.dart';
import 'bloc/export_state.dart';

class ExportScreen extends StatelessWidget {
  final String? projectId;
  final String? videoPath;

  const ExportScreen({super.key, this.projectId, this.videoPath});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<ExportBloc>()..add(const ExportInitializeRequested()),
      child: _ExportBody(projectId: projectId, videoPath: videoPath),
    );
  }
}

class _ExportBody extends StatelessWidget {
  final String? projectId;
  final String? videoPath;

  const _ExportBody({this.projectId, this.videoPath});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExportBloc, ExportState>(
      listener: (context, state) {
        if (state is ExportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: ${state.message}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: state is! ExportSuccess
              ? AppBar(
                  backgroundColor: AppColors.backgroundDark,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(
                      Iconsax.arrow_left,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  title: Text(
                    AppStrings.exportVideo,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  centerTitle: false,
                )
              : null,
          body: switch (state) {
            ExportInitial() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ExportReady() => _buildReadyState(context, state),
            ExportInProgress() => _buildProgress(state),
            ExportSuccess() => _buildSuccess(context, state),
            ExportFailure() => _buildReady(context),
          },
        );
      },
    );
  }

  Widget _buildReady(BuildContext context) {
    final state = context.read<ExportBloc>().state;
    if (state is ExportReady) return _buildReadyState(context, state);
    return const SizedBox.shrink();
  }

  Widget _buildReadyState(BuildContext context, ExportReady state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          _buildPreview(),
          const SizedBox(height: 28),

          // Format Selection
          _buildSectionTitle('Format'),
          const SizedBox(height: 12),
          _buildFormatChips(context, state),
          const SizedBox(height: 24),

          // Resolution Selection
          _buildSectionTitle('Resolution'),
          const SizedBox(height: 12),
          _buildResolutionChips(context, state),
          const SizedBox(height: 24),

          // AI Features (pro)
          _buildSectionTitle('AI Features'),
          const SizedBox(height: 12),
          _buildFeatureToggle(
            context: context,
            icon: Iconsax.subtitle,
            title: AppStrings.aiCaptions,
            subtitle: 'Auto-generate subtitles',
            value: state.aiCaptionsEnabled,
            isPro: state.isPro,
            onChanged: (val) {
              if (state.isPro) {
                context.read<ExportBloc>().add(ExportAiCaptionsToggled(val));
              } else {
                context.push('/paywall');
              }
            },
          ),
          const SizedBox(height: 10),
          _buildFeatureToggle(
            context: context,
            icon: Iconsax.magicpen,
            title: AppStrings.backgroundRemoval,
            subtitle: 'Remove video background',
            value: state.bgRemovalEnabled,
            isPro: state.isPro,
            onChanged: (val) {
              if (state.isPro) {
                context.read<ExportBloc>().add(ExportBgRemovalToggled(val));
              } else {
                context.push('/paywall');
              }
            },
          ),
          const SizedBox(height: 36),

          // Export Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<ExportBloc>().add(ExportStarted(
                        projectId: projectId,
                        videoPath: videoPath,
                      ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Iconsax.export_1, color: Colors.white),
                label: Text(
                  AppStrings.export_,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quality note for free users
          if (!state.isPro)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.info_circle,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Free export includes watermark. Upgrade to Pro for HD quality & no watermark.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: videoPath != null && videoPath!.isNotEmpty && File(videoPath!).existsSync()
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const Center(
                child: Icon(
                  Iconsax.video_play,
                  size: 52,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Iconsax.video_play,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 10),
                Text(
                  'Video Preview',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildFormatChips(BuildContext context, ExportReady state) {
    const formats = [
      ('MP4', 'mp4'),
      ('MOV', 'mov'),
      ('GIF', 'gif'),
    ];
    return Row(
      children: formats.map((f) {
        final isSelected = state.selectedFormat == f.$2;
        final isProFormat = f.$2 == 'gif' && !state.isPro;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () {
              if (isProFormat) {
                context.push('/paywall');
                return;
              }
              context.read<ExportBloc>().add(ExportFormatChanged(f.$2));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.cardDark.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    f.$1,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  if (isProFormat) ...[
                    const SizedBox(width: 4),
                    const Icon(Iconsax.lock, size: 12, color: AppColors.proBadge),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResolutionChips(BuildContext context, ExportReady state) {
    final resolutions = [
      ('360p', '360p', false),
      ('480p', '480p', false),
      ('720p', '720p', false),
      ('1080p', '1080p', true),
      ('4K', '4k', true),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: resolutions.map((r) {
        final isSelected = state.selectedResolution == r.$2;
        final requiresPro = r.$3 && !state.isPro;
        return GestureDetector(
          onTap: () {
            if (requiresPro) {
              context.push('/paywall');
              return;
            }
            context.read<ExportBloc>().add(ExportResolutionChanged(r.$2));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppColors.cardDark.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  r.$1,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                if (requiresPro) ...[
                  const SizedBox(width: 4),
                  const Icon(Iconsax.crown_1, size: 11, color: AppColors.proBadge),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureToggle({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isPro,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardDark.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.accent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!isPro) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.proBadgeGradientStart,
                              AppColors.proBadgeGradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'PRO',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            inactiveTrackColor: AppColors.cardDark,
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(ExportInProgress state) {
    final percent = (state.progress * 100).toInt();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: state.progress,
                      strokeWidth: 6,
                      backgroundColor:
                          AppColors.surfaceDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.exporting,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              percent < 50
                  ? 'Processing video...'
                  : percent < 90
                      ? 'Saving to gallery...'
                      : 'Finishing up...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, ExportSuccess state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.success,
                    Color(0xFF00BCD4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.exportComplete,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              state.savedPath != null
                  ? 'Your video has been saved to the ClipAI album in your gallery.'
                  : 'Your video has been exported successfully.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            // Share button
            if (state.savedPath != null)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.shareXFiles(
                        [XFile(state.savedPath!)],
                        subject: 'Check out my video made with ClipAI!',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Iconsax.share, color: Colors.white),
                    label: Text(
                      'Share Video',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.textTertiary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
