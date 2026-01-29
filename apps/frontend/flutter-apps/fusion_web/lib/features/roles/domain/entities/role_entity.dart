// Role Entity - Core business object
class RoleEntity {
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSystem;
  final int userCount;

  const RoleEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.createdAt,
    this.updatedAt,
    required this.isSystem,
    required this.userCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'RoleEntity{id: $id, name: $name, permissions: ${permissions.length}}';
  }
}
