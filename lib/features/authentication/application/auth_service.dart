import '../../../../core/errors/result.dart';
import '../../../../core/services/base_service.dart';
import '../domain/entities/user_entity.dart';
import '../domain/repositories/auth_repository.dart';

/// Authentication service — coordinates auth business rules.
/// Future phases will implement the method bodies.
abstract class AuthService extends BaseService {
  final AuthRepository repository;

  AuthService({required this.repository});

  Future<Result<AuthSessionEntity>> signIn({
    required String email,
    required String password,
  });

  Future<Result<AuthSessionEntity>> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<Result<void>> signOut();

  Future<Result<void>> requestPasswordReset({required String email});

  Stream<AuthSessionEntity?> get authStateChanges;
}