import 'package:fusion_design_tool_prototype/features/dashboard/domain/entities/get_projects_entity.dart';

class GetProjectsResponseDto {
  final int id;
  final String name;
  final String description;
  final int ownerId;
  final String metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  GetProjectsResponseDto({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GetProjectsResponseDto.fromJson(Map<String, dynamic> json) {
    return GetProjectsResponseDto(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      ownerId: json['owner_id'] as int,
      metadata: json['metadata'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  GetProjectsEntity toEntity() {
    return GetProjectsEntity(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory GetProjectsResponseDto.fromEntity(GetProjectsEntity entity) {
    return GetProjectsResponseDto(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      ownerId: entity.ownerId,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
