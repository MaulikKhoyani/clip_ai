import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/api_constants.dart';
import 'core/di/injection.dart';
import 'core/firebase_options.dart';
import 'core/observers/crashlytics_bloc_observer.dart';
import 'data/datasources/supabase_datasource.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0D0D),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ── Firebase ──
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass all Flutter framework errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass async/platform errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ── Supabase ──
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );

  // ── Local storage ──
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('cache');

  // ── Dependency injection ──
  await configureDependencies();

  // ── BLoC Crashlytics observer ──
  Bloc.observer = CrashlyticsBlocObserver(getIt<AnalyticsService>());

  // ── FCM notifications ──
  await NotificationService.instance.initialize(getIt<SupabaseDataSource>());

  // TODO: Initialize RevenueCat when API keys are added
  // await Purchases.configure(PurchasesConfiguration(
  //   Platform.isIOS ? ApiConstants.revenueCatAppleKey : ApiConstants.revenueCatGoogleKey,
  // ));

  runApp(const ClipAiApp());
}
