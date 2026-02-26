import 'package:fusion_lib/models/project_entities/project_metadata_model.dart';

class NewProjectDetails {
  final String name;
  final ProjectMetaData metadata;

  NewProjectDetails({
    required this.name,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'metadata': metadata.toJson(),
    };
  }

  NewProjectDetails copyWith({
    String? name,
    ProjectMetaData? metadata,
  }) {
    return NewProjectDetails(
      name: name ?? this.name,
      metadata: metadata ?? this.metadata,
    );
  }
}
