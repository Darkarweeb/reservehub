/// Domain entity representing an authenticated user.
class UserEntity {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.lastSignInAt,
  });

  UserEntity copyWith({
    String? displayName,
    String? avatarUrl,
    DateTime? lastSignInAt,
  }) {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserEntity(id: $id, email: $email)';
}

/// Domain entity representing an auth session.
class AuthSessionEntity {
  final UserEntity user;
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  const AuthSessionEntity({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
