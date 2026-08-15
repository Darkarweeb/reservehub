import '../../domain/entities/user_entity.dart';

/// Data model for [UserEntity] — maps Supabase auth.users to domain.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.avatarUrl,
    required super.createdAt,
    super.lastSignInAt,
  });

  factory UserModel.fromSupabaseUser(Map<String, dynamic> json) {
    final metadata = json['user_metadata'] as Map<String, dynamic>? ?? {};
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName:
          metadata['full_name'] as String? ??
          metadata['name'] as String? ??
          metadata['display_name'] as String?,
      avatarUrl: metadata['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.parse(json['last_sign_in_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
    'last_sign_in_at': lastSignInAt?.toIso8601String(),
  };
}

/// Data model for [AuthSessionEntity].
class AuthSessionModel extends AuthSessionEntity {
  const AuthSessionModel({
    required super.user,
    required super.accessToken,
    super.refreshToken,
    required super.expiresAt,
  });

  factory AuthSessionModel.fromSupabaseSession(
    Map<String, dynamic> sessionJson,
    Map<String, dynamic> userJson,
  ) {
    final user = UserModel.fromSupabaseUser(userJson);
    final expiresAt = sessionJson['expires_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            (sessionJson['expires_at'] as int) * 1000,
          )
        : DateTime.now().add(const Duration(hours: 1));

    return AuthSessionModel(
      user: user,
      accessToken: sessionJson['access_token'] as String,
      refreshToken: sessionJson['refresh_token'] as String?,
      expiresAt: expiresAt,
    );
  }
}
