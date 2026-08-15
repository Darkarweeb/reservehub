import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Supabase implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl({required SupabaseClient client}) : _client = client;

  @override
  Future<AuthSessionEntity?> getCurrentSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return null;
      final user = _client.auth.currentUser;
      if (user == null) return null;
      return _mapSession(session, user);
    } catch (e, st) {
      AppLogger.error(
        'getCurrentSession failed',
        tag: 'AuthRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  Future<Result<AuthSessionEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null || response.user == null) {
        return failure(
          const AuthFailure(
            message: 'Sign in failed. Please check your credentials.',
          ),
        );
      }
      return success(_mapSession(response.session!, response.user!));
    } on AuthException catch (e) {
      AppLogger.warning('signIn AuthException: ${e.message}', tag: 'AuthRepo');
      return failure(_mapAuthException(e));
    } catch (e, st) {
      AppLogger.error(
        'signIn failed',
        tag: 'AuthRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AuthSessionEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'full_name': displayName} : null,
      );
      if (response.user == null) {
        return failure(
          const AuthFailure(message: 'Sign up failed. Please try again.'),
        );
      }
      if (response.session == null) {
        final signInResult = await signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return signInResult;
      }
      return success(_mapSession(response.session!, response.user!));
    } on AuthException catch (e) {
      AppLogger.warning('signUp AuthException: ${e.message}', tag: 'AuthRepo');
      return failure(_mapAuthException(e));
    } catch (e, st) {
      AppLogger.error(
        'signUp failed',
        tag: 'AuthRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return success(null);
    } on AuthException catch (e) {
      return failure(_mapAuthException(e));
    } catch (e, st) {
      AppLogger.error(
        'signOut failed',
        tag: 'AuthRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return success(null);
    } on AuthException catch (e) {
      return failure(_mapAuthException(e));
    } catch (e, st) {
      AppLogger.error(
        'sendPasswordReset failed',
        tag: 'AuthRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AuthSessionEntity>> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      if (response.session == null || response.user == null) {
        return failure(const SessionExpiredFailure());
      }
      return success(_mapSession(response.session!, response.user!));
    } on AuthException catch (e) {
      return failure(_mapAuthException(e));
    } catch (e, st) {
      AppLogger.error(
        'refreshSession failed',
        tag: 'AuthRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<AuthSessionEntity?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final session = data.session;
      final user = data.session?.user;
      if (session == null || user == null) return null;
      return _mapSession(session, user);
    });
  }

  @override
  void dispose() {}

  // ─── Private helpers ───────────────────────────────────────────────────────

  AuthSessionEntity _mapSession(Session session, User user) {
    final userModel = UserModel.fromSupabaseUser({
      'id': user.id,
      'email': user.email ?? '',
      'user_metadata': user.userMetadata ?? {},
      'created_at': user.createdAt,
      'last_sign_in_at': user.lastSignInAt,
    });

    final expiresAt = session.expiresAt != null
        ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
        : DateTime.now().add(const Duration(hours: 1));

    return AuthSessionModel(
      user: userModel,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: expiresAt,
    );
  }

  Failure _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return const AuthFailure(message: 'Invalid email or password.');
    }
    if (msg.contains('email already') || msg.contains('already registered')) {
      return const ConflictFailure(
        message: 'An account with this email already exists.',
      );
    }
    if (msg.contains('weak password')) {
      return const ValidationFailure(
        message: 'Password is too weak. Use at least 8 characters.',
      );
    }
    if (msg.contains('rate limit')) {
      return const ServerFailure(
        message: 'Too many attempts. Please wait a moment.',
      );
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return const NetworkFailure();
    }
    return AuthFailure(message: e.message);
  }
}
