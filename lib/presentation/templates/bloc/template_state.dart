import 'package:equatable/equatable.dart';
import 'package:clip_ai/domain/entities/template_entity.dart';

sealed class TemplateState extends Equatable {
  const TemplateState();
  @override
  List<Object?> get props => [];
}

class TemplatesInitial extends TemplateState {}

class TemplatesLoading extends TemplateState {}

class TemplatesLoaded extends TemplateState {
  final List<TemplateEntity> templates;
  final String selectedCategory;
  final bool isPro;

  const TemplatesLoaded({
    required this.templates,
    required this.selectedCategory,
    required this.isPro,
  });

  @override
  List<Object?> get props => [templates, selectedCategory, isPro];
}

class TemplatesError extends TemplateState {
  final String message;
  const TemplatesError(this.message);
  @override
  List<Object?> get props => [message];
}
