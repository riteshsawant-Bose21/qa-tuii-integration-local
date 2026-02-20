// create a model class for project metadata with the following properties:
// projectId, name, description, metadata, createdAt, updatedAt

import 'dart:convert';

class ProjectMetadata {
  final String fileId;
  final String projectName;
  final String thumbnailUrl;

  ProjectMetadata({
    required this.fileId,
    required this.thumbnailUrl,
    required this.projectName,
  });

  factory ProjectMetadata.fromJson(Map<String, dynamic> json) {
    return ProjectMetadata(
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

  static ProjectMetadata empty() {
    return ProjectMetadata(
      fileId: '',
      thumbnailUrl: '',
      projectName: '',
    );
  }

  ProjectMetadata copyWith({
    String? fileId,
    String? thumbnailUrl,
    String? projectName,
  }) {
    return ProjectMetadata(
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
