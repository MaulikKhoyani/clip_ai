import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_editor/video_editor.dart';

import 'package:clip_ai/core/constants/app_colors.dart';
import 'package:clip_ai/domain/entities/project_entity.dart';
import 'package:clip_ai/domain/repositories/project_repository.dart';
import 'package:clip_ai/services/subscription_service.dart';
import 'package:clip_ai/services/video_editing_service.dart';

class VideoEditorPage extends StatefulWidget {
  final String videoPath;
  const VideoEditorPage({super.key, required this.videoPath});

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage>
    with SingleTickerProviderStateMixin {
  late VideoEditorController _controller;
  late TabController _tabController;

  bool _initialized = false;
  bool _isExporting = false;
  // ignore: unused_field — reserved for future FFmpeg progress callback
  double _exportProgress = 0.0;
  int _selectedFilterIndex = 0;

  // Adjust tab state
  double _speed = 1.0;
  double _volume = 1.0;
  int _rotation = 0;
  bool _flipH = false;
  bool _flipV = false;

  VideoEditingService get _videoService => GetIt.I<VideoEditingService>();
  SubscriptionService get _subscriptionService => GetIt.I<SubscriptionService>();
  ProjectRepository get _projectRepository => GetIt.I<ProjectRepository>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initController();
  }

  Future<void> _initController() async {
    _controller = VideoEditorController.file(
      File(widget.videoPath),
      minDuration: const Duration(seconds: 1),
      maxDuration: const Duration(minutes: 3),
    );
    try {
      await _controller.initialize(aspectRatio: 9 / 16);
      setState(() => _initialized = true);
    } catch (e) {
      if (mounted) {
        _showError('Failed to load video: $e');
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Export ───────────────────────────────────────────────────────────────

  Future<void> _export() async {
    // Step 1: Show quality selection sheet
    final isPro = await _subscriptionService.isProUser;
    if (!mounted) return;

    final selectedQuality = await _showQualitySheet(isPro: isPro);
    if (selectedQuality == null || !mounted) return; // user cancelled

    final use1080p = selectedQuality == '1080p';

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    final selectedFilter = videoFilters[_selectedFilterIndex];
    final hasFilter = selectedFilter.ffmpegFilter.isNotEmpty;
    final hasAdjustments = _speed != 1.0 || _volume != 1.0 ||
        _rotation != 0 || _flipH || _flipV;

    VideoExportResult result;

    if (!hasFilter && !hasAdjustments) {
      result = await _videoService.trimVideoFast(
        inputPath: widget.videoPath,
        startTrim: _controller.startTrim,
        endTrim: _controller.endTrim,
      );
    } else {
      result = await _videoService.exportVideo(
        inputPath: widget.videoPath,
        startTrim: _controller.startTrim,
        endTrim: _controller.endTrim,
        filter: hasFilter ? selectedFilter : null,
        isPro: use1080p,
        addWatermark: false,
        speed: _speed,
        volume: _volume,
        rotation: _rotation,
        flipH: _flipH,
        flipV: _flipV,
      );
    }

    setState(() => _isExporting = false);
    if (!mounted) return;

    if (result.isSuccess) {
      // Step 2: Save project to Supabase
      await _saveProject(_controller.trimmedDuration, result.outputPath!);
      if (!mounted) return;
      // Step 3: Show share/save sheet
      await _showShareSheet(result.outputPath!);
    } else {
      _showError(result.error ?? 'Export failed');
    }
  }

  Future<void> _saveProject(Duration trimmedDuration, String outputPath) async {
    final now = DateTime.now();
    final title =
        'Video ${now.day}/${now.month} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final createResult = await _projectRepository.createProject(title: title);
    if (!createResult.isSuccess) {
      debugPrint('Failed to create project: ${createResult.error.message}');
      return;
    }

    final entity = createResult.data;
    final updated = ProjectEntity(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      durationSeconds: trimmedDuration.inSeconds,
      projectMeta: {'video_path': outputPath},
      status: 'exported',
      lastExportedAt: now,
      createdAt: entity.createdAt,
      updatedAt: now,
    );
    await _projectRepository.updateProject(updated);
  }

  // ─── Exit / Draft ─────────────────────────────────────────────────────────

  /// Called whenever the user tries to leave the editor (close button or
  /// Android back gesture). Shows a bottom sheet with Exit / Save as Draft.
  Future<void> _showExitSheet() async {
    if (_isExporting) return; // don't interrupt an active export

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExitSheet(),
    );

    if (!mounted) return;

    if (choice == 'draft') {
      await _saveDraft();
    } else if (choice == 'exit') {
      Navigator.of(context).pop(false);
    }
    // null = user dismissed sheet → stay in editor
  }

  Future<void> _saveDraft() async {
    setState(() => _isExporting = true); // reuse loader while saving

    final now = DateTime.now();
    final title =
        'Draft ${now.day}/${now.month} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final createResult = await _projectRepository.createProject(title: title);

    setState(() => _isExporting = false);
    if (!mounted) return;

    if (!createResult.isSuccess) {
      _showError('Could not save draft. Please try again.');
      return;
    }

    final entity = createResult.data;
    final durationSec =
        _initialized ? _controller.trimmedDuration.inSeconds : null;

    final updated = ProjectEntity(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      durationSeconds: durationSec,
      projectMeta: {'video_path': widget.videoPath},
      status: 'draft',
      createdAt: entity.createdAt,
      updatedAt: now,
    );
    await _projectRepository.updateProject(updated);

    if (mounted) Navigator.of(context).pop(true); // true = refresh home/projects
  }

  // ─── Quality Selection Sheet ──────────────────────────────────────────────

  Future<String?> _showQualitySheet({required bool isPro}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QualitySheet(isPro: isPro),
    );
  }

  // ─── Share Sheet ──────────────────────────────────────────────────────────

  Future<void> _showShareSheet(String exportedPath) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VideoShareSheet(videoPath: exportedPath),
    );
    // Return true so caller knows a project was saved and should refresh
    if (mounted) Navigator.of(context).pop(true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitSheet();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: !_initialized
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _isExporting
                ? _buildExportingView()
                : _buildEditorBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: _showExitSheet,
      ),
      title: Text(
        'Edit Video',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
      actions: [
        if (!_isExporting && _initialized)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _export,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'Export',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
      bottom: _initialized
          ? TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Trim'),
                Tab(text: 'Filter'),
                Tab(text: 'Adjust'),
              ],
            )
          : null,
    );
  }

  Widget _buildEditorBody() {
    // Responsive tab panel height: 28% of screen height, clamped between 200–260
    final tabHeight = (MediaQuery.of(context).size.height * 0.28).clamp(200.0, 260.0);

    return Column(
      children: [
        // ── Video Preview ────────────────────────────────────────────────
        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CropGridViewer.preview(controller: _controller),
                  // Play / pause overlay
                  GestureDetector(
                    onTap: () {
                      _controller.video.value.isPlaying
                          ? _controller.video.pause()
                          : _controller.video.play();
                      setState(() {});
                    },
                    child: AnimatedOpacity(
                      opacity:
                          _controller.video.value.isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // ── Tab Content ──────────────────────────────────────────────────
        Container(
          color: const Color(0xFF0D0D0D),
          height: tabHeight,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTrimTab(),
              _buildFilterTab(),
              _buildAdjustTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Trim Tab ─────────────────────────────────────────────────────────────

  Widget _buildTrimTab() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Duration info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _timeLabel('Start', _controller.startTrim),
                  _durationBadge(_controller.trimmedDuration),
                  _timeLabel('End', _controller.endTrim),
                ],
              ),
              const SizedBox(height: 8),
              // Trim slider
              TrimSlider(
                controller: _controller,
                height: 56,
                horizontalMargin: 4,
                child: TrimTimeline(
                  controller: _controller,
                  padding: const EdgeInsets.only(top: 4),
                ),
              ),
              const SizedBox(height: 8),
              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _controlBtn(Icons.replay_5, () {
                    final pos = _controller.video.value.position -
                        const Duration(seconds: 5);
                    _controller.video.seekTo(
                        pos < Duration.zero ? Duration.zero : pos);
                  }),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      _controller.video.value.isPlaying
                          ? _controller.video.pause()
                          : _controller.video.play();
                      setState(() {});
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _controller.video.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _controlBtn(Icons.forward_5, () {
                    final pos = _controller.video.value.position +
                        const Duration(seconds: 5);
                    final max = _controller.endTrim;
                    _controller.video
                        .seekTo(pos > max ? max : pos);
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _timeLabel(String label, Duration d) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(_formatDuration(d),
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _durationBadge(Duration d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Text(
        _formatDuration(d),
        style: GoogleFonts.inter(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _controlBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Filter Tab ───────────────────────────────────────────────────────────

  Widget _buildFilterTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: videoFilters.length,
        itemBuilder: (_, i) => _filterItem(i),
      ),
    );
  }

  Widget _filterItem(int index) {
    final filter = videoFilters[index];
    final selected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(filter.emoji,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filter.name,
              style: GoogleFonts.inter(
                color: selected ? AppColors.primary : Colors.white70,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Adjust Tab ───────────────────────────────────────────────────────────

  Widget _buildAdjustTab() {
    const speedPresets = [0.25, 0.5, 1.0, 1.5, 2.0, 4.0];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Speed ──────────────────────────────────────────────────────
          _adjustSectionLabel('Speed'),
          const SizedBox(height: 8),
          Row(
            children: speedPresets.map((s) {
              final selected = _speed == s;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _speed = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.primary : Colors.white12,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      s == 1.0 ? '1×' : '$s×',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: selected ? AppColors.primary : Colors.white70,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Volume ─────────────────────────────────────────────────────
          Row(
            children: [
              _adjustSectionLabel('Volume'),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(
                    () => _volume = _volume == 0.0 ? 1.0 : 0.0),
                child: Row(
                  children: [
                    Icon(
                      _volume == 0.0
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: _volume == 0.0
                          ? AppColors.error
                          : Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _volume == 0.0 ? 'Muted' : 'Mute',
                      style: GoogleFonts.inter(
                          color: _volume == 0.0
                              ? AppColors.error
                              : Colors.white54,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white12,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _volume,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              onChanged: (v) => setState(() => _volume = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%',
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 10)),
              Text(
                '${(_volume * 100).round()}%',
                style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              Text('200%',
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Rotate & Flip ──────────────────────────────────────────────
          _adjustSectionLabel('Rotate & Flip'),
          const SizedBox(height: 8),
          Row(
            children: [
              _adjustIconBtn(
                icon: Icons.rotate_left_rounded,
                label: 'Left 90°',
                onTap: () {
                  setState(() => _rotation = (_rotation - 90 + 360) % 360);
                  _controller.rotate90Degrees();
                },
              ),
              const SizedBox(width: 10),
              _adjustIconBtn(
                icon: Icons.rotate_right_rounded,
                label: 'Right 90°',
                onTap: () {
                  setState(() => _rotation = (_rotation + 90) % 360);
                  _controller.rotate90Degrees();
                },
              ),
              const SizedBox(width: 10),
              _adjustIconBtn(
                icon: Icons.flip_rounded,
                label: 'Flip H',
                active: _flipH,
                onTap: () => setState(() => _flipH = !_flipH),
              ),
              const SizedBox(width: 10),
              _adjustIconBtn(
                icon: Icons.flip_rounded,
                label: 'Flip V',
                active: _flipV,
                onTap: () => setState(() => _flipV = !_flipV),
                rotated: true,
              ),
            ],
          ),
          if (_rotation != 0 || _flipH || _flipV)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Rotation: $_rotation°${_flipH ? ' · Flip H' : ''}${_flipV ? ' · Flip V' : ''}',
                style: GoogleFonts.inter(
                    color: AppColors.primary, fontSize: 11),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _adjustSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5),
    );
  }

  Widget _adjustIconBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    bool rotated = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primary : Colors.white12,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotatedBox(
                quarterTurns: rotated ? 1 : 0,
                child: Icon(
                  icon,
                  color: active ? AppColors.primary : Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: active ? AppColors.primary : Colors.white54,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Exporting View ───────────────────────────────────────────────────────

  Widget _buildExportingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Exporting video...',
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait',
            style: GoogleFonts.inter(
                color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Exit Confirmation Sheet ──────────────────────────────────────────────────

class _ExitSheet extends StatelessWidget {
  const _ExitSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.edit_note_rounded,
                color: Colors.white70, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            'Exit Editing?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your progress as a draft or exit without saving.',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 28),

          // Save as Draft button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'draft'),
                icon: const Icon(Icons.bookmark_outline_rounded,
                    color: Colors.white, size: 20),
                label: Text(
                  'Save as Draft',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Exit without saving button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, 'exit'),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
              label: Text(
                'Exit without Saving',
                style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Cancel — stay in editor
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Editing',
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quality Selection Bottom Sheet ───────────────────────────────────────────

class _QualitySheet extends StatefulWidget {
  final bool isPro;
  const _QualitySheet({required this.isPro});

  @override
  State<_QualitySheet> createState() => _QualitySheetState();
}

class _QualitySheetState extends State<_QualitySheet> {
  String _selected = '720p';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Export Quality',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the output resolution',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _qualityOption(
            label: '720p',
            subtitle: 'Standard HD · Smaller file size',
            badge: null,
          ),
          const SizedBox(height: 12),
          _qualityOption(
            label: '1080p',
            subtitle: 'Full HD · Best quality',
            badge: widget.isPro ? null : 'PRO',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_selected == '1080p' && !widget.isPro) {
                    Navigator.pop(context);
                    // Optionally navigate to paywall — for now just use 720p
                    return;
                  }
                  Navigator.pop(context, _selected);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Export $_selected',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qualityOption({
    required String label,
    required String subtitle,
    required String? badge,
  }) {
    final selected = _selected == label;
    final locked = badge == 'PRO';
    return GestureDetector(
      onTap: () => setState(() => _selected = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (locked)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          ],
        ),
      ),
    );
  }
}

// ─── Share Bottom Sheet ────────────────────────────────────────────────────────

class VideoShareSheet extends StatefulWidget {
  final String videoPath;
  const VideoShareSheet({super.key, required this.videoPath});

  @override
  State<VideoShareSheet> createState() => VideoShareSheetState();
}

class VideoShareSheetState extends State<VideoShareSheet> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _saveToGallery() async {
    setState(() => _saving = true);
    final result = await GallerySaver.saveVideo(widget.videoPath, albumName: 'ClipAI');
    setState(() {
      _saving = false;
      _saved = result == true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == true ? 'Saved to gallery!' : 'Save failed. Try again.',
          ),
          backgroundColor:
              result == true ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _shareGeneral() {
    Share.shareXFiles(
      [XFile(widget.videoPath)],
      subject: 'Check out my video made with ClipAI!',
    );
  }

  void _shareToApp(String appName) {
    Share.shareXFiles(
      [XFile(widget.videoPath)],
      subject: 'Check out my video made with ClipAI!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Success icon
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.success, Color(0xFF00BCD4)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Export Complete!',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your video is ready. What would you like to do?',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 28),

          // Save to Gallery
          _actionButton(
            icon: Icons.save_alt_rounded,
            label: _saved ? 'Saved to Gallery!' : 'Save to Gallery',
            color: _saved ? AppColors.success : AppColors.primary,
            loading: _saving,
            onTap: _saved ? null : _saveToGallery,
          ),
          const SizedBox(height: 12),

          // Share row — Instagram, WhatsApp, Facebook, More
          Row(
            children: [
              Expanded(
                child: _socialButton(
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  icon: Icons.camera_alt_rounded,
                  onTap: () => _shareToApp('Instagram'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _socialButton(
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  icon: Icons.chat_rounded,
                  onTap: () => _shareToApp('WhatsApp'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _socialButton(
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  icon: Icons.people_rounded,
                  onTap: () => _shareToApp('Facebook'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _socialButton(
                  label: 'More',
                  color: Colors.white24,
                  icon: Icons.more_horiz_rounded,
                  onTap: _shareGeneral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Done button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: color),
              )
            else
              Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
