import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clip_ai/services/imgly_service.dart';
import 'package:clip_ai/services/video_editing_service.dart';
import 'package:clip_ai/services/notification_service.dart';
import 'package:clip_ai/services/subscription_service.dart';
import 'package:clip_ai/services/analytics_service.dart';

import 'package:clip_ai/data/datasources/supabase_datasource.dart';
import 'package:clip_ai/data/datasources/local_datasource.dart';

import 'package:clip_ai/data/repositories/auth_repository_impl.dart';
import 'package:clip_ai/data/repositories/project_repository_impl.dart';
import 'package:clip_ai/data/repositories/template_repository_impl.dart';
import 'package:clip_ai/data/repositories/export_repository_impl.dart';

import 'package:clip_ai/domain/repositories/auth_repository.dart';
import 'package:clip_ai/domain/repositories/project_repository.dart';
import 'package:clip_ai/domain/repositories/template_repository.dart';
import 'package:clip_ai/domain/repositories/export_repository.dart';

import 'package:clip_ai/presentation/auth/bloc/auth_bloc.dart';
import 'package:clip_ai/presentation/home/bloc/home_bloc.dart';
import 'package:clip_ai/presentation/templates/bloc/template_bloc.dart';
import 'package:clip_ai/presentation/projects/bloc/projects_bloc.dart';
import 'package:clip_ai/presentation/export/bloc/export_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  getIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // Services
  getIt.registerLazySingleton<ImglyService>(
    () => ImglyService(),
  );
  getIt.registerLazySingleton<VideoEditingService>(
    () => VideoEditingService(),
  );

  getIt.registerLazySingleton<SubscriptionService>(
    () => SubscriptionService(),
  );

  final analyticsService = AnalyticsService();
  await analyticsService.initialize();
  getIt.registerSingleton<AnalyticsService>(analyticsService);

  getIt.registerSingleton<NotificationService>(NotificationService.instance);

  // Data Sources
  getIt.registerLazySingleton<SupabaseDataSource>(
    () => SupabaseDataSource(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<LocalDataSource>(
    () => LocalDataSource(),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<SupabaseDataSource>()),
  );
  getIt.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(
      getIt<SupabaseDataSource>(),
      getIt<LocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<TemplateRepository>(
    () => TemplateRepositoryImpl(getIt<SupabaseDataSource>()),
  );
  getIt.registerLazySingleton<ExportRepository>(
    () => ExportRepositoryImpl(getIt<SupabaseDataSource>()),
  );

  // BLoCs (factory = new instance each time)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      authRepository: getIt<AuthRepository>(),
      subscriptionService: getIt<SubscriptionService>(),
      analyticsService: getIt<AnalyticsService>(),
    ),
  );
  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(
      authRepository: getIt<AuthRepository>(),
      projectRepository: getIt<ProjectRepository>(),
      templateRepository: getIt<TemplateRepository>(),
      subscriptionService: getIt<SubscriptionService>(),
      analyticsService: getIt<AnalyticsService>(),
    ),
  );
  getIt.registerFactory<TemplateBloc>(
    () => TemplateBloc(
      templateRepository: getIt<TemplateRepository>(),
      subscriptionService: getIt<SubscriptionService>(),
    ),
  );
  getIt.registerFactory<ProjectsBloc>(
    () => ProjectsBloc(
      projectRepository: getIt<ProjectRepository>(),
      subscriptionService: getIt<SubscriptionService>(),
      analyticsService: getIt<AnalyticsService>(),
    ),
  );
  getIt.registerFactory<ExportBloc>(
    () => ExportBloc(
      exportRepository: getIt<ExportRepository>(),
      subscriptionService: getIt<SubscriptionService>(),
      analyticsService: getIt<AnalyticsService>(),
    ),
  );
}
