// create a model class for project metadata with the following properties:
// projectId, name, description, metadata, createdAt, updatedAt

import 'dart:convert';

class ProjectMetadataModel {
  final String fileId;
  final String projectName;
  final String thumbnailUrl;

  ProjectMetadataModel({
    required this.fileId,
    required this.thumbnailUrl,
    required this.projectName,
  });

  factory ProjectMetadataModel.fromJson(Map<String, dynamic> json) {
    return ProjectMetadataModel(
      fileId: json['file_id'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      projectName: json['project_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'file_id': fileId,
      'thumbnail_url': thumbnailUrl,
      'project_name': projectName,
    };
  }

  ProjectMetadataModel copyWith({
    String? fileId,
    String? thumbnailUrl,
    String? projectName,
  }) {
    return ProjectMetadataModel(
      fileId: fileId ?? this.fileId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      projectName: projectName ?? this.projectName,
    );
  }

  @override
  String toString() {
    return jsonEncode(
      toJson(),
    );
  }
}
