import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clip_ai/domain/repositories/auth_repository.dart';
import 'package:clip_ai/domain/repositories/project_repository.dart';
import 'package:clip_ai/domain/repositories/template_repository.dart';
import 'package:clip_ai/services/subscription_service.dart';
import 'package:clip_ai/services/analytics_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthRepository _authRepository;
  final ProjectRepository _projectRepository;
  final TemplateRepository _templateRepository;
  final SubscriptionService _subscriptionService;
  final AnalyticsService _analyticsService;

  HomeBloc({
    required AuthRepository authRepository,
    required ProjectRepository projectRepository,
    required TemplateRepository templateRepository,
    required SubscriptionService subscriptionService,
    required AnalyticsService analyticsService,
  })  : _authRepository = authRepository,
        _projectRepository = projectRepository,
        _templateRepository = templateRepository,
        _subscriptionService = subscriptionService,
        _analyticsService = analyticsService,
        super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoadRequested);
    on<HomeRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    await _loadHome(emit);
  }

  Future<void> _onRefreshRequested(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    await _loadHome(emit);
  }

  Future<void> _loadHome(Emitter<HomeState> emit) async {
    try {
      final user = await _authRepository.currentUser;
      if (user == null) {
        emit(const HomeError('User not found'));
        return;
      }

      final projectsResult = await _projectRepository.getProjects();
      final templatesResult = await _templateRepository.getFeaturedTemplates();
      final isPro = await _subscriptionService.isProUser;

      projectsResult.when(
        success: (projects) {
          templatesResult.when(
            success: (templates) {
              emit(HomeLoaded(
                user: user,
                recentProjects: projects,
                featuredTemplates: templates,
                isPro: isPro,
              ));
            },
            failure: (e) => emit(HomeError(e.message)),
          );
        },
        failure: (e) => emit(HomeError(e.message)),
      );
    } catch (e, stackTrace) {
      await _analyticsService.recordError(e, stackTrace, reason: 'HomeBloc._loadHome');
      emit(HomeError(e.toString()));
    }
  }
}
