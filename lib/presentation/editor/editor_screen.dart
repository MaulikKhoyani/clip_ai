import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:clip_ai/core/constants/app_colors.dart';
import 'package:clip_ai/core/constants/app_strings.dart';
import 'package:clip_ai/presentation/editor/video_editor_page.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  // ─── Navigation to VideoEditorPage ───────────────────────────────────────

  Future<void> _openCamera(BuildContext context) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 3),
    );
    if (video == null) return;
    if (!context.mounted) return;
    _openEditor(context, video.path);
  }

  Future<void> _importFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    if (!context.mounted) return;
    _openEditor(context, video.path);
  }

  Future<void> _openAiClipping(BuildContext context) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    if (!context.mounted) return;
    // Open editor — user trims to create the "AI clip"
    _openEditor(context, video.path, isAiClipping: true);
  }

  Future<void> _openTemplates(BuildContext context) async {
    // Templates: pick a video, then open editor with template info
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    if (!context.mounted) return;
    _openEditor(context, video.path);
  }

  Future<void> _openDrafts(BuildContext context) async {
    // Drafts: TODO — will show saved draft list in future
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Drafts coming soon'),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openEditor(BuildContext context, String videoPath,
      {bool isAiClipping = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VideoEditorPage(videoPath: videoPath),
      ),
    ).then((exportedPath) {
      if (exportedPath != null && context.mounted) {
        _showSuccess(context, exportedPath as String);
      }
    });
  }

  void _showSuccess(BuildContext context, String exportedPath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Video exported successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => context.push(
            '/export',
            extra: {'videoPath': exportedPath},
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppStrings.newProject,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start with',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MainActionCard(
                    title: AppStrings.recordVideo,
                    subtitle: 'Record with camera',
                    icon: Iconsax.camera,
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
                  child: _MainActionCard(
                    title: AppStrings.importVideo,
                    subtitle: 'From gallery',
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
            ),
            const SizedBox(height: 32),
            Text(
              'More options',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Iconsax.magicpen,
              title: 'AI Clipping',
              subtitle: 'Pick a video and trim highlights',
              iconGradient: const [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
              onTap: () => _openAiClipping(context),
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Iconsax.element_3,
              title: AppStrings.templates,
              subtitle: 'Import video and apply template',
              iconGradient: const [Color(0xFF6C5CE7), Color(0xFF00D2FF)],
              onTap: () => _openTemplates(context),
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Iconsax.document,
              title: 'Drafts',
              subtitle: 'Continue editing saved drafts',
              iconGradient: const [Color(0xFF00E676), Color(0xFF00BCD4)],
              onTap: () => _openDrafts(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _MainActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _MainActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient)
                  .colors
                  .first
                  .withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> iconGradient;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconGradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.cardDark.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: iconGradient
                      .map((c) => c.withValues(alpha: 0.2))
                      .toList(),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(colors: iconGradient).createShader(bounds),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: AppColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
