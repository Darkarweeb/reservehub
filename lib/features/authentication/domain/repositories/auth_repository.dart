import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';
import '../entities/user_entity.dart';

/// Contract for authentication data operations.
/// Implemented in the infrastructure layer (Supabase, mock, etc.).
abstract interface class AuthRepository implements BaseRepository {
  /// Returns the currently authenticated session, or null if signed out.
  Future<AuthSessionEntity?> getCurrentSession();

  /// Signs in with email and password.
  Future<Result<AuthSessionEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Creates a new account with email and password.
  Future<Result<AuthSessionEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs the current user out and clears the local session.
  Future<Result<void>> signOut();

  /// Sends a password reset email.
  Future<Result<void>> sendPasswordResetEmail({required String email});

  /// Refreshes the current session token.
  Future<Result<AuthSessionEntity>> refreshSession();

  /// Stream of auth state changes.
  Stream<AuthSessionEntity?> get authStateChanges;
}
