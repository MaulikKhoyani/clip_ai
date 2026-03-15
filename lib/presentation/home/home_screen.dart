import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:clip_ai/core/constants/app_colors.dart';
import 'package:clip_ai/core/constants/app_strings.dart';
import 'package:clip_ai/domain/entities/project_entity.dart';
import 'package:clip_ai/domain/repositories/project_repository.dart';
import 'package:clip_ai/presentation/editor/video_editor_page.dart';
import 'package:clip_ai/presentation/home/bloc/home_bloc.dart';
import 'package:clip_ai/presentation/home/bloc/home_event.dart';
import 'package:clip_ai/presentation/home/bloc/home_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<HomeBloc>()..add(HomeLoadRequested()),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            floatingActionButton: _buildFab(context),
            body: switch (state) {
              HomeLoading() => _buildShimmer(),
              HomeLoaded() => _buildContent(context, state),
              HomeError() => _buildError(context, state.message),
              _ => const SizedBox.shrink(),
            },
          );
        },
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => context.push('/editor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildShimmer() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _ShimmerBox(width: 200, height: 28),
            const SizedBox(height: 8),
            _ShimmerBox(width: 140, height: 16),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _ShimmerBox(height: 140)),
                const SizedBox(width: 16),
                Expanded(child: _ShimmerBox(height: 140)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeLoaded state) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: () async {
          context.read<HomeBloc>().add(HomeRefreshRequested());
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 16),
            _buildGreeting(context, state),
            const SizedBox(height: 28),
            _buildQuickActions(context),
            const SizedBox(height: 32),
            _buildRecentProjects(context, state),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, HomeLoaded state) {
    final name = state.user.displayName ?? 'Creator';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $name',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'What will you create today?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.accent.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    (state.user.displayName ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (state.isPro)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
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
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 3),
    );
    if (video == null) return;
    if (!context.mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VideoEditorPage(videoPath: video.path),
      ),
    );
    if (saved == true && context.mounted) {
      context.read<HomeBloc>().add(HomeRefreshRequested());
    }
  }

  Future<void> _importFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    if (!context.mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VideoEditorPage(videoPath: video.path),
      ),
    );
    if (saved == true && context.mounted) {
      context.read<HomeBloc>().add(HomeRefreshRequested());
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            title: AppStrings.recordVideo,
            icon: Iconsax.video,
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => _openCamera(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _QuickActionCard(
            title: AppStrings.importVideo,
            icon: Iconsax.gallery_import,
            gradient: const LinearGradient(
              colors: [Color(0xFF00D2FF), Color(0xFF0097B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => _importFromGallery(context),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentProjects(BuildContext context, HomeLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recentProjects,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (state.recentProjects.isEmpty)
          _buildEmptyProjects()
        else
          ...state.recentProjects.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProjectTile(
                project: p,
                onDeleted: () =>
                    context.read<HomeBloc>().add(HomeRefreshRequested()),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyProjects() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cardDark.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.video_play,
            size: 48,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noProjects,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.startCreating,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
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
              onPressed: () =>
                  context.read<HomeBloc>().add(HomeLoadRequested()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppStrings.retry,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient)
                  .colors
                  .first
                  .withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final ProjectEntity project;
  final VoidCallback onDeleted;

  const _ProjectTile({required this.project, required this.onDeleted});

  String? get _videoPath => project.projectMeta['video_path'] as String?;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardDark.withValues(alpha: 0.5)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.accent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.video_play,
                color: AppColors.textSecondary, size: 24),
          ),
          title: Text(
            project.title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                project.formattedDuration,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textTertiary),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                    color: AppColors.textTertiary, shape: BoxShape.circle),
              ),
              Text(
                project.isDraft ? 'Draft' : 'Exported',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: project.isDraft ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.more_vert_rounded,
              color: AppColors.textTertiary, size: 20),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Iconsax.edit_2, color: AppColors.primary),
              title: Text('Edit Video',
                  style: GoogleFonts.inter(color: AppColors.textPrimary)),
              onTap: () async {
                Navigator.pop(context);
                if (_videoPath == null) return;
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => VideoEditorPage(videoPath: _videoPath!),
                  ),
                );
                if (saved == true && context.mounted) onDeleted();
              },
            ),
            ListTile(
              leading: Icon(Iconsax.export_1, color: AppColors.accent),
              title: Text('Export / Share',
                  style: GoogleFonts.inter(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                if (_videoPath == null) return;
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => VideoShareSheet(videoPath: _videoPath!),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Iconsax.trash, color: AppColors.error),
              title: Text('Delete',
                  style: GoogleFonts.inter(color: AppColors.error)),
              onTap: () => _confirmDelete(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Navigator.pop(context); // close options sheet first
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Project',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        content: Text(
          'Delete "${project.title}"? This cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel,
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await GetIt.I<ProjectRepository>()
                  .deleteProject(project.id);
              onDeleted();
            },
            child: Text(AppStrings.delete,
                style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;

  _ShimmerBox({this.width, this.height = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
