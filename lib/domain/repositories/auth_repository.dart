import '../entities/user_entity.dart';
import '../../core/errors/result.dart';

abstract class AuthRepository {
  Stream<bool> get authStateChanges;
  Future<UserEntity?> get currentUser;
  Future<Result<UserEntity>> signInWithEmail(String email, String password);
  Future<Result<UserEntity>> signUpWithEmail(String email, String password, String displayName);
  Future<Result<UserEntity>> signInWithGoogle();
  Future<Result<UserEntity>> signInWithApple();
  Future<Result<void>> signOut();
  Future<Result<void>> resetPassword(String email);
  Future<Result<void>> updateProfile({String? displayName, String? avatarUrl});
  Future<Result<void>> deleteAccount();
}
