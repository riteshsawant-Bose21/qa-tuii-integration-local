import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ProjectData {
  final String id;
  final String name;
  final String projectName;
  final List<Color> colors;
  final String metaData;
  final double minSPL;
  final double maxSPL;
  final String? virtualIP;
  final Map<String, dynamic> projectRawData;

  ProjectData({
    String? id,
    required this.name,
    required this.metaData,
    String? projectName,
    List<Color>? projectColors,
    required this.projectRawData,
    this.minSPL = 0.0,
    this.maxSPL = 120.0,
    this.virtualIP,
  }) : id = id ?? const Uuid().v4(),
       projectName = projectName ?? name,
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
  }) {
    return ProjectData(
      id: id ?? this.id,
      name: name ?? this.name,
      projectName: projectName ?? this.projectName,
      projectColors: colors ?? this.colors,
      metaData: metaData ?? this.metaData,
      projectRawData: projectRawData ?? this.projectRawData,
      virtualIP: virtualIP ?? this.virtualIP,
      minSPL: minSPL ?? this.minSPL,
      maxSPL: maxSPL ?? this.maxSPL,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'projectName': projectName,
      'metaData': metaData,
      'projectRawData': projectRawData,
      'projectColors': colors.map((Color color) => color.value.toString()).toList(),
      'minSPL': minSPL,
      'maxSPL': maxSPL,
      'virtualIP': virtualIP,
    };
  }

  static ProjectData fromJson(Map<String, dynamic> json) {
    return ProjectData(
      id: json['id'] as String?,
      name: json['name'] as String,
      projectName: json['projectName'] as String? ?? json['name'] as String,
      metaData: json['metaData'] as String,
      projectColors:
          (json['projectColors'] as List<dynamic>?)?.map((dynamic e) => Color(int.parse(e.toString()))).toList() ?? <Color>[Colors.green, Colors.greenAccent],
      projectRawData: json,
      minSPL: (json['minSPL'] as num?)?.toDouble() ?? 0.0,
      maxSPL: (json['maxSPL'] as num?)?.toDouble() ?? 120.0,
      virtualIP: json['virtualIP'] as String?,
    );
  }
}
