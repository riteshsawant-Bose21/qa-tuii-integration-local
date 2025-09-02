import 'package:flutter/material.dart';

import '../../fusion_lib.dart';

/// -------------------
/// Project Service
/// -------------------
class ProjectService {
  final String id;
  final String name;
  final String projectName;
  final List<Color> colors;
  final String? virtualIP;
  int currentFloorIndex;
  final Map<String, dynamic>? droResponse;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String metaData;
  final double minSPL;
  final double maxSPL;
  bool isInControlMode;

  final FloorRepository floors;
  final ListeningAreaRepository listeningAreas;
  final ZoneRepository zones;
  final SourceSetRepository sourceSets;
  final HardwareRepository hardware;
  final FusionDeviceRepository fusionDevices;
  final FusionDeviceRepository suggestedFusionDevices;
  final AmplifierRepository amplifiers;

  final RelationshipManager relationships;

  ProjectService({
    required this.id,
    required this.name,
    required this.projectName,
    required this.colors,
    this.virtualIP,
    this.currentFloorIndex = 0,
    this.droResponse,
    required this.createdAt,
    required this.updatedAt,
    required this.metaData,
    required this.minSPL,
    required this.maxSPL,
    this.isInControlMode = false,
    FloorRepository? floors,
    ListeningAreaRepository? listeningAreas,
    ZoneRepository? zones,
    SourceSetRepository? sourceSets,
    HardwareRepository? hardware,
    FusionDeviceRepository? fusionDevices,
    FusionDeviceRepository? suggestedFusionDevices,
    AmplifierRepository? amplifiers,
    RelationshipManager? relationships,
  }) : floors = floors ?? FloorRepository(),
       listeningAreas = listeningAreas ?? ListeningAreaRepository(),
       zones = zones ?? ZoneRepository(),
       sourceSets = sourceSets ?? SourceSetRepository(),
       hardware = hardware ?? HardwareRepository(),
       fusionDevices = fusionDevices ?? FusionDeviceRepository(),
       suggestedFusionDevices = suggestedFusionDevices ?? FusionDeviceRepository(),
       amplifiers = amplifiers ?? AmplifierRepository(),
       relationships = relationships ?? RelationshipManager();

  ProjectService copyWith({
    String? id,
    String? name,
    String? projectName,
    List<Color>? colors,
    String? virtualIP,
    int? currentFloorIndex,
    Map<String, dynamic>? droResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? metaData,
    double? minSPL,
    double? maxSPL,
    bool? isInControlMode,
    FloorRepository? floors,
    ListeningAreaRepository? listeningAreas,
    ZoneRepository? zones,
    SourceSetRepository? sourceSets,
    HardwareRepository? hardware,
    FusionDeviceRepository? fusionDevices,
    FusionDeviceRepository? suggestedFusionDevices,
    AmplifierRepository? amplifiers,
    RelationshipManager? relationships,
  }) {
    return ProjectService(
      id: id ?? this.id,
      name: name ?? this.name,
      projectName: projectName ?? this.projectName,
      colors: colors ?? this.colors,
      virtualIP: virtualIP ?? this.virtualIP,
      currentFloorIndex: currentFloorIndex ?? this.currentFloorIndex,
      droResponse: droResponse ?? this.droResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metaData: metaData ?? this.metaData,
      minSPL: minSPL ?? this.minSPL,
      maxSPL: maxSPL ?? this.maxSPL,
      isInControlMode: isInControlMode ?? this.isInControlMode,
      floors: floors ?? this.floors,
      listeningAreas: listeningAreas ?? this.listeningAreas,
      zones: zones ?? this.zones,
      sourceSets: sourceSets ?? this.sourceSets,
      hardware: hardware ?? this.hardware,
      fusionDevices: fusionDevices ?? this.fusionDevices,
      suggestedFusionDevices: suggestedFusionDevices ?? this.suggestedFusionDevices,
      amplifiers: amplifiers ?? this.amplifiers,
      relationships: relationships ?? this.relationships,
    );
  }

  /// -------------------
  /// Queries
  /// -------------------

  /// -------------------
  /// JSON
  /// -------------------

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "projectName": name,
      "colors": colors.map((c) => c.value).toList(),
      "virtualIP": virtualIP,
      "currentFloorIndex": currentFloorIndex,
      "droResponse": droResponse,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "metaData": metaData,
      "minSPL": minSPL,
      "maxSPL": maxSPL,
      "isInControlMode": isInControlMode,
      "floors": floors.toJson((f) => f.toJson()),
      "listeningAreas": listeningAreas.toJson((a) => a.toJson()),
      "zones": zones.toJson((z) => z.toJson()),
      "sourceSet": sourceSets.toJson((m) => m.toJson()),
      "hardware": hardware.toJson((HardwareComponent c) {
        if (c is Source) {
          return c.toJson();
        } else if (c is Speaker) {
          return c.toJson();
        } else {
          return (c as GenericHardwareComponent).toJson();
        }
      }),
      "fusionDevices": fusionDevices.toJson((f) => f.toJson()),
      "suggestedFusionDevices": suggestedFusionDevices.toJson((f) => f.toJson()),
      "amplifiers": amplifiers.toJson((a) => a.toJson()),
      "relationships": relationships.toJson(),
    };
  }

  factory ProjectService.fromJson(Map<String, dynamic> json) {
    final service = ProjectService(
      id: json["id"],
      name: json["name"],
      projectName: json["projectName"],
      colors: (json['colors'] as List<dynamic>?)?.map((dynamic e) => Color(int.parse(e.toString()))).toList() ?? <Color>[Colors.green, Colors.greenAccent],
      virtualIP: json["virtualIP"],
      currentFloorIndex: json["currentFloorIndex"] ?? 0,
      droResponse: json["droResponse"],
      createdAt: DateTime.parse(json["createdAt"]),
      updatedAt: DateTime.parse(json["updatedAt"]),
      metaData: json["metaData"] ?? "",
      minSPL: (json["minSPL"] as num).toDouble(),
      maxSPL: (json["maxSPL"] as num).toDouble(),
      isInControlMode: json["isInControlMode"] ?? false,
    );

    service.floors.fromJsonList(json["floors"], (m) => FloorModel.fromJson(m), "id");
    service.listeningAreas.fromJsonList(json["listeningAreas"], (m) => ListeningArea.fromJson(m), "id");
    service.zones.fromJsonList(json["zones"], (m) => Zone.fromJson(m), "id");
    service.sourceSets.fromJsonList(json["sourceSet"], (m) => SourceSet.fromJson(m), "id");
    service.hardware.fromJsonList(json["hardware"], (dynamic e) {
      final Map<String, dynamic> m = e as Map<String, dynamic>;
      if (m.containsKey('componentType') && m['componentType'] == 'source') {
        return Source.fromJson(m);
      } else if (m.containsKey('componentType') && m['componentType'] == 'speaker') {
        return Speaker.fromJson(m);
      } else {
        return GenericHardwareComponent.fromJson(m);
      }
    }, "id");
    service.fusionDevices.fromJsonList(json["fusionDevices"], (m) => FusionDevice.fromJson(m), "id");
    service.suggestedFusionDevices.fromJsonList(json["suggestedFusionDevices"], (m) => FusionDevice.fromJson(m), "id");
    service.amplifiers.fromJsonList(json["amplifiers"], (m) => Amplifier.fromJson(m), "id");

    service.relationships.fromJson(json["relationships"]);

    return service;
  }
}
