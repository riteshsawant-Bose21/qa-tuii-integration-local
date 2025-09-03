import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:uuid/uuid.dart';

class ProjectListModel {
  final String id;
  final String name;
  final ProjectMetadataModel metaData;
  final List<Color> colors;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectListModel({
    String? id,
    required this.name,
    required this.metaData,
    required this.colors,
    required this.createdAt,
    required this.updatedAt,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'metaData': metaData.toString(),
      'colors': colors,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProjectListModel.fromJson(Map<String, dynamic> json) {
    final dynamic metaDataJsonString = json['metaData'];
    final Map<String, dynamic> decodedMetaData = metaDataJsonString is String ? jsonDecode(metaDataJsonString) : metaDataJsonString;

    return ProjectListModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      metaData: ProjectMetadataModel.fromJson(decodedMetaData),
      colors:
          (json['colors'] as List<dynamic>?)
              ?.map(
                (dynamic e) => Color(int.parse(e.toString())),
              )
              .toList() ??
          <Color>[Colors.green, Colors.greenAccent],
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  ProjectListModel copyWith({
    String? id,
    String? name,
    ProjectMetadataModel? metaData,
    List<Color>? colors,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      metaData: metaData ?? this.metaData,
      colors: colors ?? this.colors,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
