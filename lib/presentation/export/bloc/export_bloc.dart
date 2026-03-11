import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:clip_ai/domain/repositories/export_repository.dart';
import 'package:clip_ai/services/subscription_service.dart';
import 'package:clip_ai/services/analytics_service.dart';
import 'export_event.dart';
import 'export_state.dart';

class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final ExportRepository _exportRepository;
  final SubscriptionService _subscriptionService;
  final AnalyticsService _analyticsService;

  ExportBloc({
    required ExportRepository exportRepository,
    required SubscriptionService subscriptionService,
    required AnalyticsService analyticsService,
  })  : _exportRepository = exportRepository,
        _subscriptionService = subscriptionService,
        _analyticsService = analyticsService,
        super(ExportInitial()) {
    on<ExportInitializeRequested>(_onInitialize);
    on<ExportFormatChanged>(_onFormatChanged);
    on<ExportResolutionChanged>(_onResolutionChanged);
    on<ExportAiCaptionsToggled>(_onAiCaptionsToggled);
    on<ExportBgRemovalToggled>(_onBgRemovalToggled);
    on<ExportStarted>(_onExportStarted);
  }

  Future<void> _onInitialize(
    ExportInitializeRequested event,
    Emitter<ExportState> emit,
  ) async {
    final isPro = await _subscriptionService.isProUser;
    emit(ExportReady(
      selectedFormat: 'mp4',
      selectedResolution: '720p',
      aiCaptionsEnabled: false,
      bgRemovalEnabled: false,
      isPro: isPro,
    ));
  }

  void _onFormatChanged(ExportFormatChanged event, Emitter<ExportState> emit) {
    if (state is ExportReady) {
      emit((state as ExportReady).copyWith(selectedFormat: event.format));
    }
  }

  void _onResolutionChanged(
    ExportResolutionChanged event,
    Emitter<ExportState> emit,
  ) {
    if (state is ExportReady) {
      emit((state as ExportReady).copyWith(selectedResolution: event.resolution));
    }
  }

  void _onAiCaptionsToggled(
    ExportAiCaptionsToggled event,
    Emitter<ExportState> emit,
  ) {
    if (state is ExportReady) {
      emit((state as ExportReady).copyWith(aiCaptionsEnabled: event.enabled));
    }
  }

  void _onBgRemovalToggled(
    ExportBgRemovalToggled event,
    Emitter<ExportState> emit,
  ) {
    if (state is ExportReady) {
      emit((state as ExportReady).copyWith(bgRemovalEnabled: event.enabled));
    }
  }

  Future<void> _onExportStarted(
    ExportStarted event,
    Emitter<ExportState> emit,
  ) async {
    final ready = state as ExportReady;

    emit(const ExportInProgress(progress: 0.0));

    final projectId = event.projectId ?? 'unknown';
    await _analyticsService.logExportStarted(
      projectId: projectId,
      resolution: ready.selectedResolution,
      format: ready.selectedFormat,
    );

    final startTime = DateTime.now();

    try {
      // Save video to gallery if path is provided
      String? savedPath;
      if (event.videoPath != null && event.videoPath!.isNotEmpty) {
        emit(const ExportInProgress(progress: 0.4));
        final saved = await GallerySaver.saveVideo(
          event.videoPath!,
          albumName: 'ClipAI',
        );
        if (saved == true) savedPath = event.videoPath;
      }

      emit(const ExportInProgress(progress: 0.8));

      // Log export to Supabase
      if (event.projectId != null) {
        await _exportRepository.logExport(
          projectId: event.projectId!,
          format: ready.selectedFormat,
          resolution: ready.selectedResolution,
          usedAiCaptions: ready.aiCaptionsEnabled,
          usedBgRemoval: ready.bgRemovalEnabled,
        );
      }

      emit(const ExportInProgress(progress: 1.0));
      await Future.delayed(const Duration(milliseconds: 300));

      final durationSeconds =
          DateTime.now().difference(startTime).inSeconds;
      await _analyticsService.logExportCompleted(
        projectId: projectId,
        fileSizeMb: 0.0,
        durationSeconds: durationSeconds,
      );

      emit(ExportSuccess(savedPath: savedPath));
    } catch (e, stackTrace) {
      await _analyticsService.recordError(e, stackTrace, reason: 'ExportBloc._onExportStarted');
      emit(ExportFailure(e.toString()));
    }
  }
}
