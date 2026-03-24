class GetProjectsEntity {
  final int id;
  final String name;
  final String description;
  final int ownerId;
  final String metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  GetProjectsEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });
}
