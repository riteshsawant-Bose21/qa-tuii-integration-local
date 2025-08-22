import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/constants/spl_calculation_data.dart';
import 'package:fusion_launcher/core/models/amplifer.dart';
import 'package:fusion_launcher/core/models/fusion_device.dart';
import 'package:fusion_lib/models/fusion_models.dart';
import 'package:uuid/uuid.dart';

import 'floor_entity.dart';
import 'mix_entity.dart';

class ProjectEntity {
  final String id;
  final String cloudId;
  final String name;
  final String projectName;
  final List<Color> colors;
  final List<Floor> floors;
  final List<Zone> zones;
  final List<Mix> mixes;
  final List<HardwareComponent> hardwareComponents;
  final List<FusionDevice> fusionDevices;
  final List<FusionDevice> suggestedFusionDevices;
  final List<Amplifier> amplifiers;
  final String? virtualIP;
  int currentFloorIndex;
  final Map<String, dynamic>? droResponse;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String metaData;
  final double minSPL;
  final double maxSPL;
  bool isInControlMode;

  ProjectEntity({
    String? id,
    String? cloudId,
    required this.name,
    required this.metaData,
    String? projectName,
    List<Color>? colors,
    List<Floor>? floors,
    List<Zone>? zones,
    List<Mix>? mixes,
    this.currentFloorIndex = 0,
    List<HardwareComponent>? hardwareComponents,
    List<FusionDevice>? fusionDevices,
    List<FusionDevice>? suggestedFusionDevices,
    List<Amplifier>? amplifiers,
    this.virtualIP,
    this.droResponse,
    required this.createdAt,
    required this.updatedAt,
    this.minSPL = SPLCalculationData.defaultMinSPL,
    this.maxSPL = SPLCalculationData.defaultMaxSPL,
    this.isInControlMode = false,
  }) : id = id ?? const Uuid().v4(),
       cloudId = cloudId ?? const Uuid().v4(),
       floors = floors ?? <Floor>[],
       colors = colors ?? <Color>[Colors.green, Colors.greenAccent],
       zones = zones ?? <Zone>[],
       hardwareComponents = hardwareComponents ?? <HardwareComponent>[],
       mixes = mixes ?? <Mix>[],
       amplifiers = amplifiers ?? <Amplifier>[],
       fusionDevices = fusionDevices ?? <FusionDevice>[],
       projectName = projectName ?? name,
       suggestedFusionDevices = suggestedFusionDevices ?? <FusionDevice>[];

  Floor get currentFloor => floors[currentFloorIndex];

  ProjectEntity copyWith({
    String? id,
    String? cloudId,
    String? name,
    String? projectName,
    List<Floor>? floors,
    int? currentFloorIndex,
    List<Zone>? zones,
    List<Mix>? mixes,
    List<HardwareComponent>? hardwareComponents,
    List<FusionDevice>? fusionDevices,
    String? virtualIP,
    List<Color>? colors,
    String? metaData,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? droResponse,
    List<Amplifier>? amplifiers,
    double? minSPL,
    double? maxSPL,
    List<FusionDevice>? suggestedFusionDevices,
    bool? isInControlMode,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      name: name ?? this.name,
      projectName: projectName ?? this.projectName,
      metaData: metaData ?? this.metaData,
      floors: floors ?? this.floors,
      currentFloorIndex: currentFloorIndex ?? this.currentFloorIndex,
      zones: zones ?? this.zones,
      mixes: mixes ?? this.mixes,
      hardwareComponents: hardwareComponents ?? this.hardwareComponents,
      fusionDevices: fusionDevices ?? this.fusionDevices,
      virtualIP: virtualIP ?? this.virtualIP,
      droResponse: droResponse ?? this.droResponse,
      colors: colors,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      amplifiers: amplifiers ?? this.amplifiers,
      minSPL: minSPL ?? this.minSPL,
      maxSPL: maxSPL ?? this.maxSPL,
      suggestedFusionDevices: suggestedFusionDevices ?? this.suggestedFusionDevices,
      isInControlMode: isInControlMode ?? this.isInControlMode,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'cloudId': cloudId,
      'name': name,
      'projectName': projectName,
      'metaData': metaData,
      'floors': floors.map((Floor floor) => floor.toJson()).toList(),
      'currentFloorIndex': currentFloorIndex,
      'zones': zones.map((Zone zone) => zone.toJson()).toList(),
      'mixes': mixes.map((Mix mix) => mix.toJson()).toList(),
      'hardwareComponents':
          hardwareComponents.map((HardwareComponent c) {
            if (c is Source) {
              return c.toJson();
            } else if (c is Speaker) {
              return c.toJson();
            } else {
              return (c as GenericHardwareComponent).toJson();
            }
          }).toList(),
      'fusionDevices': fusionDevices.map((FusionDevice device) => device.toJson()).toList(),
      'suggestedFusionDevices': suggestedFusionDevices.map((FusionDevice device) => device.toJson()).toList(),
      'amplifiers': amplifiers.map((Amplifier device) => device.toJson()).toList(),
      'virtualIP': virtualIP,
      'droResponse': droResponse,
      'minSPL': minSPL,
      'maxSPL': maxSPL,
      'colors': colors.map((Color color) => color.value.toString()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isInControlMode': isInControlMode,
    };
  }

  static ProjectEntity fromJson(Map<String, dynamic> json) {
    return ProjectEntity(
      id: json['id'] as String?,
      cloudId: json['cloudId'] as String?,
      name: json['name'] as String,
      projectName: json['projectName'] as String? ?? json['name'] as String,
      metaData: json['metaData'] as String,
      floors: (json['floors'] as List<dynamic>).map((dynamic e) => Floor.fromJson(e as Map<String, dynamic>)).toList(),
      currentFloorIndex: json['currentFloorIndex'] as int? ?? 0,
      zones: (json['zones'] as List<dynamic>).map((dynamic e) => Zone.fromJson(e as Map<String, dynamic>)).toList(),
      mixes: (json['mixes'] as List<dynamic>).map((dynamic e) => Mix.fromJson(e as Map<String, dynamic>)).toList(),
      hardwareComponents:
          (json['hardwareComponents'] as List<dynamic>).map<HardwareComponent>((dynamic e) {
            final Map<String, dynamic> m = e as Map<String, dynamic>;
            if (m.containsKey('componentType') && m['componentType'] == 'source') {
              return Source.fromJson(m);
            } else if (m.containsKey('componentType') && m['componentType'] == 'speaker') {
              return Speaker.fromJson(m);
            } else {
              return GenericHardwareComponent.fromJson(m);
            }
          }).toList(),
      fusionDevices: (json['fusionDevices'] as List<dynamic>?)?.map((dynamic e) => FusionDevice.fromJson(e as Map<String, dynamic>)).toList(),
      suggestedFusionDevices:
          (json['suggestedFusionDevices'] as List<dynamic>?)?.map((dynamic e) => FusionDevice.fromJson(e as Map<String, dynamic>)).toList() ?? <FusionDevice>[],
      amplifiers: (json['amplifiers'] as List<dynamic>?)?.map((dynamic e) => Amplifier.fromJson(e as Map<String, dynamic>)).toList() ?? <Amplifier>[],
      virtualIP: json['virtualIP'] as String?,
      droResponse: json["droResponse"],
      colors: (json['colors'] as List<dynamic>?)?.map((dynamic e) => Color(int.parse(e.toString()))).toList() ?? <Color>[Colors.green, Colors.greenAccent],
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      minSPL: (json['minSPL'] as num?)?.toDouble() ?? SPLCalculationData.defaultMinSPL,
      maxSPL: (json['maxSPL'] as num?)?.toDouble() ?? SPLCalculationData.defaultMaxSPL,
      isInControlMode: json['isInControlMode'] as bool? ?? false,
    );
  }
}
