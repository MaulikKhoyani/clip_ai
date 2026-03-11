import 'package:equatable/equatable.dart';

sealed class TemplateEvent extends Equatable {
  const TemplateEvent();
  @override
  List<Object?> get props => [];
}

class TemplatesLoadRequested extends TemplateEvent {}

class TemplatesCategoryChanged extends TemplateEvent {
  final String? category;
  const TemplatesCategoryChanged(this.category);
  @override
  List<Object?> get props => [category];
}
