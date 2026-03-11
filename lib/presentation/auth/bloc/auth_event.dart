import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInWithEmail extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInWithEmail({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpWithEmail extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  const AuthSignUpWithEmail({
    required this.email,
    required this.password,
    required this.displayName,
  });
  @override
  List<Object?> get props => [email, password, displayName];
}

class AuthSignInWithGoogle extends AuthEvent {}

class AuthSignInWithApple extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthResetPassword extends AuthEvent {
  final String email;
  const AuthResetPassword({required this.email});
  @override
  List<Object?> get props => [email];
}

class AuthUpdateProfile extends AuthEvent {
  final String? displayName;
  final String? avatarUrl;
  const AuthUpdateProfile({this.displayName, this.avatarUrl});
  @override
  List<Object?> get props => [displayName, avatarUrl];
}

class AuthDeleteAccountRequested extends AuthEvent {}
