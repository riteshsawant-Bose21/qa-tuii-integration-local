// User Entity - Core business object
class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? avatar;
  final List<String> permissions;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
    this.avatar,
    required this.permissions,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
