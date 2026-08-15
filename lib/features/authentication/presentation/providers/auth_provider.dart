import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Authentication state for the application.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Provider managing authentication state.
/// Listens to Supabase auth state changes and exposes current user.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initial;
  AuthSessionEntity? _session;
  String? _errorMessage;

  AuthProvider({required AuthRepository repository})
    : _repository = repository {
    _initialize();
  }

  // ─── Getters ───────────────────────────────────────────────────────────────

  AuthStatus get status => _status;
  AuthSessionEntity? get session => _session;
  UserEntity? get currentUser => _session?.user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final currentSession = await _repository.getCurrentSession();
      if (currentSession != null) {
        _session = currentSession;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      AppLogger.error(
        'AuthProvider init failed',
        tag: 'AuthProvider',
        error: e,
      );
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();

    // Listen to ongoing auth state changes
    _repository.authStateChanges.listen(
      (session) {
        _session = session;
        _status = session != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        AppLogger.error(
          'Auth state stream error',
          tag: 'AuthProvider',
          error: e,
        );
      },
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<bool> signIn({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return result.fold(
      onSuccess: (session) {
        _session = session;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      },
      onFailure: (failure) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );

    return result.fold(
      onSuccess: (session) {
        _session = session;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      },
      onFailure: (failure) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _repository.signOut();
    _session = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendPasswordReset({required String email}) async {
    final result = await _repository.sendPasswordResetEmail(email: email);
    return result.isSuccess;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
