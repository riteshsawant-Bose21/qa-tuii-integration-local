// create a model class for project metadata with the following properties:
// projectId, name, notes, metadata, createdAt, updatedAt

import 'dart:convert';

import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_building_view/floor_plan_calibrator.dart';

class ProjectMetaData {
  final String fileId;
  final String projectName;
  final String thumbnailUrl;
  final String organisationName;
  final String? fileVersion;
  final String? authorName;
  final List<String> tags;
  final String? category;
  final String? notes;
  final String? state;
  final FusionCountries? country;
  final FusionTimeZones? timeZone;
  final String? primaryBuildingName;
  final String? budget;
  final CurrencyType? currency;
  final MeasurementUnit? measurementUnit;
  final String? temperature;
  final String? projectGoals;

  const ProjectMetaData({
    required this.fileId,
    required this.thumbnailUrl,
    required this.projectName,
    required this.organisationName,
    this.fileVersion,
    this.authorName,
    this.tags = const [],
    this.category,
    this.notes,
    this.state,
    this.country,
    this.timeZone,
    this.primaryBuildingName,
    this.budget,
    this.currency,
    this.measurementUnit,
    this.temperature,
    this.projectGoals,
  });

  factory ProjectMetaData.empty() {
    return const ProjectMetaData(
      fileId: '',
      thumbnailUrl: '',
      projectName: '',
      organisationName: '',
    );
  }

  factory ProjectMetaData.fromJson(Map<String, dynamic> json) {
    return ProjectMetaData(
      fileId: json['file_id'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      projectName: json['project_name'] ?? '',
      organisationName: json['organisation_name'] ?? '',
      fileVersion: json['file_version'],
      authorName: json['author_name'],
      tags: List<String>.from(json['tags'] ?? <String>[]),
      category: json['category'],
      notes: json['notes'],
      state: json['state'],
      country: FusionCountries.fromJson(json['country']),
      timeZone: FusionTimeZones.fromJson(json['time_zone']),
      primaryBuildingName: json['primary_building_name'],
      budget: json['budget'],
      currency: CurrencyType.fromJson(json['currency']),
      measurementUnit: MeasurementUnit.fromJson(json['measurement_unit']),
      temperature: json['temperature'],
      projectGoals: json['project_goals'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'file_id': fileId,
      'thumbnail_url': thumbnailUrl,
      'project_name': projectName,
      'organisation_name': organisationName,
      'file_version': fileVersion,
      'author_name': authorName,
      'tags': tags,
      'category': category,
      'notes': notes,
      'state': state,
      'country': country?.toJson(),
      'time_zone': timeZone?.toJson(),
      'primary_building_name': primaryBuildingName,
      'budget': budget,
      'currency': currency?.toJson(),
      'measurement_unit': measurementUnit?.toJson(),
      'temperature': temperature,
      'project_goals': projectGoals,
    };
  }

  @override
  String toString() {
    return jsonEncode(
      toJson(),
    );
  }

  ProjectMetaData copyWith({
    String? fileId,
    String? projectName,
    String? thumbnailUrl,
    String? organisationName,
    String? fileVersion,
    String? authorName,
    List<String>? tags,
    String? category,
    String? notes,
    String? state,
    FusionCountries? country,
    FusionTimeZones? timeZone,
    String? primaryBuildingName,
    String? budget,
    CurrencyType? currency,
    MeasurementUnit? measurementUnit,
    String? temperature,
    String? projectGoals,
  }) {
    return ProjectMetaData(
      fileId: fileId ?? this.fileId,
      projectName: projectName ?? this.projectName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      organisationName: organisationName ?? this.organisationName,
      fileVersion: fileVersion ?? this.fileVersion,
      authorName: authorName ?? this.authorName,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      state: state ?? this.state,
      country: country ?? this.country,
      timeZone: timeZone ?? this.timeZone,
      primaryBuildingName: primaryBuildingName ?? this.primaryBuildingName,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      temperature: temperature ?? this.temperature,
      projectGoals: projectGoals ?? this.projectGoals,
    );
  }
}
