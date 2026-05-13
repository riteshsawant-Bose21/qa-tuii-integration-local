class UserEntity {
  final String id;
  final String email;
  final String name;
  final String? picture;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.picture,
  });
}
