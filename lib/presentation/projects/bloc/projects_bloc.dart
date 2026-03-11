import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clip_ai/domain/repositories/project_repository.dart';
import 'package:clip_ai/services/subscription_service.dart';
import 'package:clip_ai/services/analytics_service.dart';
import 'projects_event.dart';
import 'projects_state.dart';

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final ProjectRepository _projectRepository;
  final SubscriptionService _subscriptionService;
  final AnalyticsService _analyticsService;

  ProjectsBloc({
    required ProjectRepository projectRepository,
    required SubscriptionService subscriptionService,
    required AnalyticsService analyticsService,
  })  : _projectRepository = projectRepository,
        _subscriptionService = subscriptionService,
        _analyticsService = analyticsService,
        super(ProjectsInitial()) {
    on<ProjectsLoadRequested>(_onLoad);
    on<ProjectsRefreshRequested>(_onRefresh);
    on<ProjectDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(
    ProjectsLoadRequested event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    await _loadProjects(emit);
  }

  Future<void> _onRefresh(
    ProjectsRefreshRequested event,
    Emitter<ProjectsState> emit,
  ) async {
    await _loadProjects(emit);
  }

  Future<void> _onDelete(
    ProjectDeleteRequested event,
    Emitter<ProjectsState> emit,
  ) async {
    final result = await _projectRepository.deleteProject(event.projectId);
    result.when(
      success: (_) => add(const ProjectsRefreshRequested()),
      failure: (e) => emit(ProjectsError(e.message)),
    );
  }

  Future<void> _loadProjects(Emitter<ProjectsState> emit) async {
    try {
      final projectsResult = await _projectRepository.getProjects();
      final isPro = await _subscriptionService.isProUser;
      projectsResult.when(
        success: (projects) => emit(
          ProjectsLoaded(projects: projects, isPro: isPro),
        ),
        failure: (e) => emit(ProjectsError(e.message)),
      );
    } catch (e, stackTrace) {
      await _analyticsService.recordError(e, stackTrace, reason: 'ProjectsBloc._loadProjects');
      emit(ProjectsError(e.toString()));
    }
  }
}
