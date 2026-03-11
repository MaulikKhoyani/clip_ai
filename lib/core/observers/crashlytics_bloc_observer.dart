import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clip_ai/services/analytics_service.dart';

/// Globally intercepts uncaught BLoC/Cubit errors and reports them
/// to Firebase Crashlytics.
class CrashlyticsBlocObserver extends BlocObserver {
  const CrashlyticsBlocObserver(this._analyticsService);

  final AnalyticsService _analyticsService;

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _analyticsService.recordError(
      error,
      stackTrace,
      reason: 'Uncaught error in ${bloc.runtimeType}',
    );
    super.onError(bloc, error, stackTrace);
  }
}
