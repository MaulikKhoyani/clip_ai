import 'package:equatable/equatable.dart';

sealed class ProjectsEvent extends Equatable {
  const ProjectsEvent();
  @override
  List<Object?> get props => [];
}

class ProjectsLoadRequested extends ProjectsEvent {
  const ProjectsLoadRequested();
}

class ProjectsRefreshRequested extends ProjectsEvent {
  const ProjectsRefreshRequested();
}

class ProjectDeleteRequested extends ProjectsEvent {
  final String projectId;
  const ProjectDeleteRequested(this.projectId);
  @override
  List<Object?> get props => [projectId];
}
