import 'package:fusion_lib/fusion_lib.dart';

class ProjectListResponse {
  final List<ProjectData> projects;
  final int totalCount;
  final int page;
  final int totalPages;
  ProjectListResponse({
    required this.projects,
    required this.totalCount,
    required this.page,
    required this.totalPages,
  });

  //from json
  factory ProjectListResponse.fromJson(Map<String, dynamic> json) {
    return ProjectListResponse(
      projects: (json['data'] as List).map((e) => ProjectData.fromProjectResponse(e as Map<String, dynamic>)).toList(),
      totalCount: json['total_count'] as int,
      page: json['page'] as int,
      totalPages: json['total_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': projects.map((e) => e.toJson()).toList(),
      'total_count': totalCount,
      'page': page,
      'total_pages': totalPages,
    };
  }
}
