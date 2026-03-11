import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import 'package:clip_ai/core/errors/app_exceptions.dart';
import 'package:clip_ai/core/errors/result.dart';
import 'package:clip_ai/data/datasources/supabase_datasource.dart';
import 'package:clip_ai/domain/entities/user_entity.dart';
import 'package:clip_ai/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  GoTrueClient get _auth => Supabase.instance.client.auth;

  // ── Auth State ──

  @override
  Stream<bool> get authStateChanges =>
      _auth.onAuthStateChange.map((state) => state.session != null);

  @override
  Future<UserEntity?> get currentUser async {
    final session = _auth.currentSession;
    if (session == null) return null;
    try {
      final model = await _dataSource.getProfile(session.user.id);
      return model.toEntity();
    } catch (_) {
      return null;
    }
  }

  // ── Email Auth ──

  @override
  Future<Result<UserEntity>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return const Failure(AuthException('Sign in failed: no user returned'));
      }

      // Try to fetch profile; if table not set up yet, build from auth data
      try {
        final profile = await _dataSource.getProfile(user.id);
        return Success(profile.toEntity());
      } catch (_) {
        return Success(UserEntity(
          id: user.id,
          email: user.email ?? email,
          displayName: user.userMetadata?['display_name'] as String?,
          createdAt: DateTime.now(),
        ));
      }
    } on AuthApiException catch (e) {
      return Failure(AuthException(e.message, code: e.code));
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity>> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      final user = response.user;
      if (user == null) {
        return const Failure(AuthException('Sign up failed: no user returned'));
      }

      // Supabase requires email confirmation by default.
      // session is null until the user clicks the confirmation link.
      if (response.session == null) {
        return Failure(AuthException(
          'Please check your email to confirm your account.',
          code: 'email_confirmation_required',
        ));
      }

      // Session exists — try to fetch existing profile
      try {
        final profile = await _dataSource.getProfile(user.id);
        return Success(profile.toEntity());
      } catch (_) {
        // Profile row doesn't exist yet — create it
        try {
          final now = DateTime.now().toIso8601String();
          final profile = await _dataSource.createProfile({
            'id': user.id,
            'email': email,
            'display_name': displayName,
            'subscription_tier': 'free',
            'onboarding_completed': false,
            'total_exports': 0,
            'created_at': now,
            'updated_at': now,
          });
          return Success(profile.toEntity());
        } catch (_) {
          // profiles table not set up yet — build UserEntity from auth data
          return Success(UserEntity(
            id: user.id,
            email: user.email ?? email,
            displayName: displayName,
            createdAt: DateTime.now(),
          ));
        }
      }
    } on AuthApiException catch (e) {
      return Failure(AuthException(e.message, code: e.code));
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  // ── OAuth ──

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    try {
      await _auth.signInWithOAuth(OAuthProvider.google);
      final userId = _auth.currentUser?.id;
      if (userId == null) {
        return const Failure(
          AuthException('Google sign in failed: no user returned'),
        );
      }
      final profile = await _dataSource.getProfile(userId);
      return Success(profile.toEntity());
    } on AuthApiException catch (e) {
      return Failure(AuthException(e.message, code: e.code));
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity>> signInWithApple() async {
    try {
      await _auth.signInWithOAuth(OAuthProvider.apple);
      final userId = _auth.currentUser?.id;
      if (userId == null) {
        return const Failure(
          AuthException('Apple sign in failed: no user returned'),
        );
      }
      final profile = await _dataSource.getProfile(userId);
      return Success(profile.toEntity());
    } on AuthApiException catch (e) {
      return Failure(AuthException(e.message, code: e.code));
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  // ── Sign Out / Reset ──

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(AuthException(e.toString()));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
      return const Success(null);
    } on AuthApiException catch (e) {
      return Failure(AuthException(e.message, code: e.code));
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  // ── Profile ──

  @override
  Future<Result<void>> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AuthException('Not authenticated'));
      }
      final data = <String, dynamic>{};
      if (displayName != null) data['display_name'] = displayName;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (data.isNotEmpty) {
        await _dataSource.updateProfile(userId, data);
      }
      return const Success(null);
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AuthException('Not authenticated'));
      }
      await _auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(AuthException(e.toString()));
    }
  }
}
