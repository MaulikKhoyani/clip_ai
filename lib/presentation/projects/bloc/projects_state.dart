import 'package:equatable/equatable.dart';
import 'package:clip_ai/domain/entities/project_entity.dart';

sealed class ProjectsState extends Equatable {
  const ProjectsState();
  @override
  List<Object?> get props => [];
}

class ProjectsInitial extends ProjectsState {}

class ProjectsLoading extends ProjectsState {}

class ProjectsLoaded extends ProjectsState {
  final List<ProjectEntity> projects;
  final bool isPro;

  const ProjectsLoaded({required this.projects, required this.isPro});

  @override
  List<Object?> get props => [projects, isPro];
}

class ProjectsError extends ProjectsState {
  final String message;
  const ProjectsError(this.message);
  @override
  List<Object?> get props => [message];
}
