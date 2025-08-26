import '../../domain/entities/create_project_entity.dart';

class CreateProjectResponseModel {
  final int id;
  final String name;

  CreateProjectResponseModel({required this.id, required this.name});

  factory CreateProjectResponseModel.fromJson(Map<String, dynamic> json) {
    return CreateProjectResponseModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  CreateProjectEntity toEntity() {
    return CreateProjectEntity(id: id, name: name);
  }

  factory CreateProjectResponseModel.fromEntity(CreateProjectEntity entity) {
    return CreateProjectResponseModel(id: entity.id, name: entity.name);
  }
}
