import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;

  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;

    // Enable Crashlytics collection in production only
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  // ── Crashlytics helpers ──

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  // ── Analytics events ──

  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  Future<void> logOnboardingComplete() async {
    await _analytics.logEvent(name: 'onboarding_complete');
  }

  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logSignIn({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logEditorOpened({required String source}) async {
    await _analytics.logEvent(
      name: 'editor_opened',
      parameters: {'source': source},
    );
  }

  Future<void> logTemplateSelected({
    required String templateId,
    required String templateName,
  }) async {
    await _analytics.logEvent(
      name: 'template_selected',
      parameters: {'template_id': templateId, 'template_name': templateName},
    );
  }

  Future<void> logAiCaptionsUsed({required String projectId}) async {
    await _analytics.logEvent(
      name: 'ai_captions_used',
      parameters: {'project_id': projectId},
    );
  }

  Future<void> logBgRemovalUsed({required String projectId}) async {
    await _analytics.logEvent(
      name: 'bg_removal_used',
      parameters: {'project_id': projectId},
    );
  }

  Future<void> logExportStarted({
    required String projectId,
    required String resolution,
    required String format,
  }) async {
    await _analytics.logEvent(
      name: 'export_started',
      parameters: {
        'project_id': projectId,
        'resolution': resolution,
        'format': format,
      },
    );
  }

  Future<void> logExportCompleted({
    required String projectId,
    required double fileSizeMb,
    required int durationSeconds,
  }) async {
    await _analytics.logEvent(
      name: 'export_completed',
      parameters: {
        'project_id': projectId,
        'file_size_mb': fileSizeMb,
        'duration_seconds': durationSeconds,
      },
    );
  }

  Future<void> logPaywallShown({required String source}) async {
    await _analytics.logEvent(
      name: 'paywall_shown',
      parameters: {'source': source},
    );
  }

  Future<void> logPurchaseStarted({required String productId}) async {
    await _analytics.logEvent(
      name: 'purchase_started',
      parameters: {'product_id': productId},
    );
  }

  Future<void> logPurchaseCompleted({
    required String productId,
    required double revenue,
  }) async {
    await _analytics.logPurchase(
      currency: 'USD',
      value: revenue,
      items: [AnalyticsEventItem(itemId: productId)],
    );
  }
}
