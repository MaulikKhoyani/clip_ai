import 'package:equatable/equatable.dart';
import 'package:clip_ai/domain/entities/user_entity.dart';
import 'package:clip_ai/domain/entities/project_entity.dart';
import 'package:clip_ai/domain/entities/template_entity.dart';

sealed class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final UserEntity user;
  final List<ProjectEntity> recentProjects;
  final List<TemplateEntity> featuredTemplates;
  final bool isPro;

  const HomeLoaded({
    required this.user,
    required this.recentProjects,
    required this.featuredTemplates,
    required this.isPro,
  });

  @override
  List<Object?> get props => [user, recentProjects, featuredTemplates, isPro];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}
