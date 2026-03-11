import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clip_ai/domain/repositories/template_repository.dart';
import 'package:clip_ai/services/subscription_service.dart';
import 'template_event.dart';
import 'template_state.dart';

class TemplateBloc extends Bloc<TemplateEvent, TemplateState> {
  final TemplateRepository _templateRepository;
  final SubscriptionService _subscriptionService;

  TemplateBloc({
    required TemplateRepository templateRepository,
    required SubscriptionService subscriptionService,
  })  : _templateRepository = templateRepository,
        _subscriptionService = subscriptionService,
        super(TemplatesInitial()) {
    on<TemplatesLoadRequested>(_onLoadRequested);
    on<TemplatesCategoryChanged>(_onCategoryChanged);
  }

  Future<void> _onLoadRequested(
    TemplatesLoadRequested event,
    Emitter<TemplateState> emit,
  ) async {
    emit(TemplatesLoading());
    await _loadTemplates(emit, category: null);
  }

  Future<void> _onCategoryChanged(
    TemplatesCategoryChanged event,
    Emitter<TemplateState> emit,
  ) async {
    emit(TemplatesLoading());
    await _loadTemplates(emit, category: event.category);
  }

  Future<void> _loadTemplates(
    Emitter<TemplateState> emit, {
    required String? category,
  }) async {
    final result = await _templateRepository.getTemplates(category: category);
    final isPro = await _subscriptionService.isProUser;

    result.when(
      success: (templates) => emit(TemplatesLoaded(
        templates: templates,
        selectedCategory: category ?? 'All',
        isPro: isPro,
      )),
      failure: (e) => emit(TemplatesError(e.message)),
    );
  }
}
