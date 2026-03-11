import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clip_ai/core/errors/app_exceptions.dart';
import 'package:clip_ai/domain/repositories/auth_repository.dart';
import 'package:clip_ai/services/subscription_service.dart';
import 'package:clip_ai/services/analytics_service.dart';
import 'package:clip_ai/services/notification_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SubscriptionService _subscriptionService;
  final AnalyticsService _analyticsService;

  AuthBloc({
    required AuthRepository authRepository,
    required SubscriptionService subscriptionService,
    required AnalyticsService analyticsService,
  })  : _authRepository = authRepository,
        _subscriptionService = subscriptionService,
        _analyticsService = analyticsService,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInWithEmail>(_onSignInWithEmail);
    on<AuthSignUpWithEmail>(_onSignUpWithEmail);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSignInWithApple>(_onSignInWithApple);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthResetPassword>(_onResetPassword);
    on<AuthUpdateProfile>(_onUpdateProfile);
    on<AuthDeleteAccountRequested>(_onDeleteAccount);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = await _authRepository.currentUser;
    if (user != null) {
      await _analyticsService.setUserId(user.id);
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignInWithEmail(
    AuthSignInWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithEmail(
      event.email,
      event.password,
    );
    if (result.isSuccess) {
      final user = result.data;
      _subscriptionService.loginUser(user.id);
      await _analyticsService.logSignIn(method: 'email');
      await _analyticsService.setUserId(user.id);
      await NotificationService.instance.onUserLoggedIn(user.id);
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthError(result.error.message));
    }
  }

  Future<void> _onSignUpWithEmail(
    AuthSignUpWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.signUpWithEmail(
      event.email,
      event.password,
      event.displayName,
    );
    if (result.isSuccess) {
      final user = result.data;
      _subscriptionService.loginUser(user.id);
      await _analyticsService.logSignUp(method: 'email');
      await _analyticsService.setUserId(user.id);
      await NotificationService.instance.onUserLoggedIn(user.id);
      emit(AuthAuthenticated(user));
    } else {
      final e = result.error;
      if (e is AuthException && e.code == 'email_confirmation_required') {
        emit(AuthEmailConfirmationRequired(event.email));
      } else {
        emit(AuthError(e.message));
      }
    }
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithGoogle();
    if (result.isSuccess) {
      final user = result.data;
      _subscriptionService.loginUser(user.id);
      await _analyticsService.logSignIn(method: 'google');
      await _analyticsService.setUserId(user.id);
      await NotificationService.instance.onUserLoggedIn(user.id);
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthError(result.error.message));
    }
  }

  Future<void> _onSignInWithApple(
    AuthSignInWithApple event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithApple();
    if (result.isSuccess) {
      final user = result.data;
      _subscriptionService.loginUser(user.id);
      await _analyticsService.logSignIn(method: 'apple');
      await _analyticsService.setUserId(user.id);
      await NotificationService.instance.onUserLoggedIn(user.id);
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthError(result.error.message));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    await _subscriptionService.logoutUser();
    emit(AuthUnauthenticated());
  }

  Future<void> _onResetPassword(
    AuthResetPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.resetPassword(event.email);
    if (result.isSuccess) {
      emit(AuthPasswordResetSent());
    } else {
      emit(AuthError(result.error.message));
    }
  }

  Future<void> _onUpdateProfile(
    AuthUpdateProfile event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _authRepository.updateProfile(
      displayName: event.displayName,
      avatarUrl: event.avatarUrl,
    );
    if (result.isSuccess) {
      final user = await _authRepository.currentUser;
      if (user != null) emit(AuthAuthenticated(user));
    } else {
      emit(AuthError(result.error.message));
    }
  }

  Future<void> _onDeleteAccount(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.deleteAccount();
    if (result.isSuccess) {
      await _subscriptionService.logoutUser();
      emit(AuthUnauthenticated());
    } else {
      emit(AuthError(result.error.message));
    }
  }
}
