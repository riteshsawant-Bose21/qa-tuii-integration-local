import 'package:flutter/material.dart';

class ProjectData {
  final String id;
  final String name;
  final String projectName;
  final List<Color> colors;
  final double minSPL;
  final double maxSPL;
  final String? virtualIP;
  final Map<String, dynamic> projectRawData;
  final String? application;
  final Map<String, dynamic>? budget;
  final String? description;
  final String? environmentType;
  final bool isArchived;
  final bool isStarred;
  final String? lockedByUser;
  final String? projectFileUrl;
  final String? projectPhase;
  final String? thumbnailUrl;
  final String? venue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUploadedAt;
  final bool isCloudInstance;
  final bool isDeleted;

  bool get isSyncNeeded {
    if (isCloudInstance) return false;
    return lastUploadedAt == null || updatedAt.isAfter(lastUploadedAt!);
  }

  ProjectData({
    required this.id,
    required this.name,
    String? projectName,
    List<Color>? projectColors,
    required this.projectRawData,
    this.minSPL = 0.0,
    this.maxSPL = 120.0,
    this.virtualIP,
    this.application,
    this.budget,
    this.description,
    this.environmentType,
    this.isArchived = false,
    this.isStarred = false,
    this.lockedByUser,
    this.projectFileUrl,
    this.projectPhase,
    this.thumbnailUrl,
    this.venue,
    required this.createdAt,
    required this.updatedAt,
    this.lastUploadedAt,
    required this.isCloudInstance,
    this.isDeleted = false,
  }) : projectName = projectName ?? name,
       colors = projectColors ?? <Color>[Colors.green, Colors.greenAccent];

  //copy with
  ProjectData copyWith({
    String? id,
    String? name,
    String? projectName,
    List<Color>? colors,
    String? metaData,
    Map<String, dynamic>? projectRawData,
    String? virtualIP,
    double? minSPL,
    double? maxSPL,
    String? application,
    Map<String, dynamic>? budget,
    String? description,
    String? environmentType,
    bool? isArchived,
    bool? isStarred,
    String? lockedByUser,
    String? projectFileUrl,
    String? projectPhase,
    String? thumbnailUrl,
    String? venue,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUploadedAt,
    bool? isCloudInstance,
    bool? isDeleted,
  }) {
    return ProjectData(
      id: id ?? this.id,
      name: name ?? this.name,
      projectName: projectName ?? this.projectName,
      projectColors: colors ?? this.colors,
      projectRawData: projectRawData ?? this.projectRawData,
      virtualIP: virtualIP ?? this.virtualIP,
      minSPL: minSPL ?? this.minSPL,
      maxSPL: maxSPL ?? this.maxSPL,
      application: application ?? this.application,
      budget: budget ?? this.budget,
      description: description ?? this.description,
      environmentType: environmentType ?? this.environmentType,
      isArchived: isArchived ?? this.isArchived,
      isStarred: isStarred ?? this.isStarred,
      lockedByUser: lockedByUser ?? this.lockedByUser,
      projectFileUrl: projectFileUrl ?? this.projectFileUrl,
      projectPhase: projectPhase ?? this.projectPhase,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      venue: venue ?? this.venue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUploadedAt: lastUploadedAt ?? this.lastUploadedAt,
      isCloudInstance: isCloudInstance ?? this.isCloudInstance,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'projectName': projectName,
      'projectRawData': projectRawData,
      'projectColors': colors.map((Color color) => color.value.toString()).toList(),
      'minSPL': minSPL,
      'maxSPL': maxSPL,
      'virtualIP': virtualIP,
      "application": application,
      "budget": budget,
      "description": description,
      "environment_type": environmentType,
      "is_archived": isArchived,
      "is_starred": isStarred,
      "locked_by_user": lockedByUser,
      "project_file_url": projectFileUrl,
      "project_phase": projectPhase,
      "thumbnail_url": thumbnailUrl,
      "venue": venue,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "lastUploadedAt": lastUploadedAt?.toIso8601String(),
      "isCloudInstance": isCloudInstance,
      "isDeleted": isDeleted,
    };
  }

  static ProjectData fromJson(Map<String, dynamic> json) {
    return ProjectData(
      id: json['id'] as String,
      name: json['name'] as String,
      projectName: json['projectName'] as String? ?? json['name'] as String,
      projectColors:
          (json['projectColors'] as List<dynamic>?)?.map((dynamic e) => Color(int.parse(e.toString()))).toList() ?? <Color>[Colors.green, Colors.greenAccent],
      minSPL: (json['minSPL'] as num?)?.toDouble() ?? 0.0,
      maxSPL: (json['maxSPL'] as num?)?.toDouble() ?? 120.0,
      virtualIP: json['virtualIP'] as String?,
      application: json["application"],
      budget: json["budget"],
      description: json["description"] ?? "",
      environmentType: json["environment_type"],
      isArchived: json["is_archived"] ?? false,
      isStarred: json["is_starred"] ?? false,
      lockedByUser: json["locked_by_user"],
      projectFileUrl: json["project_file_url"],
      projectPhase: json["project_phase"],
      thumbnailUrl: json["thumbnail_url"],
      venue: json["venue"],
      createdAt: DateTime.parse(json["createdAt"] as String),
      updatedAt: DateTime.parse(json["updatedAt"] as String),
      lastUploadedAt: json["lastUploadedAt"] != null ? DateTime.parse(json["lastUploadedAt"] as String) : null,
      isCloudInstance: json["isCloudInstance"] as bool? ?? false,
      projectRawData: json["isCloudInstance"] ? {} : json,
      isDeleted: json["is_deleted"] as bool? ?? false,
    );
  }

  static ProjectData fromProjectResponse(Map<String, dynamic> json) {
    return ProjectData(
      id: json['id'] as String,
      name: json['name'] as String,
      projectName: json['name'] as String,
      description: json['description'] as String?,
      application: json['application'] as String,
      venue: json['venue'] as String?,
      environmentType: json['environment_type'] as String?,
      projectPhase: json['project_phase'] as String?,
      budget: json['budget'],
      isArchived: json['is_archived'] as bool? ?? false,
      isStarred: json['is_starred'] as bool? ?? false,
      lockedByUser: json['locked_by_user'] as String?,
      projectFileUrl: json['project_file_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      projectRawData: {},
      isCloudInstance: true,
      isDeleted: false,
    );
  }
}
