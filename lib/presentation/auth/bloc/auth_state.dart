import 'package:equatable/equatable.dart';
import 'package:clip_ai/domain/entities/user_entity.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {}

class AuthEmailConfirmationRequired extends AuthState {
  final String email;
  const AuthEmailConfirmationRequired(this.email);
  @override
  List<Object?> get props => [email];
}
