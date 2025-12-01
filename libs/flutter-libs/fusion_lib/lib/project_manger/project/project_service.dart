import 'package:flutter/material.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';
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
  bool isInHardwareMode = false;

  final FloorRepository floors;
  final ListeningAreaRepository listeningAreas;
  final ZoneRepository zones;
  final SourceSetRepository sourceSets;
  final HardwareRepository hardware;
  final FusionDeviceRepository fusionDevices;
  final FusionDeviceRepository suggestedFusionDevices;
  final AmplifierRepository amplifiers;
  final CircuitRepository circuits;
  final SubZoneRepository subZones;
  final WiringConnectionRepository wiringConnection;
  final ProcessingBlockRepository processingBlocks;
  final ZoneFunctionRepository zoneFunctions;
  final PrioritySourceDataRepository prioritySourceData;
  final ScenesRepository scenes;
  final SceneActionRepository sceneActions;
  final SceneSetRepository sceneSets;
  final GPIORepository gpioConfig;

  final RelationshipManager relationships;

  // -----------------
  // Undo / Redo state
  // -----------------
  List<Map<String, dynamic>> undoStack = [];
  List<Map<String, dynamic>> redoStack = [];

  int get maxHistory => 25;

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
    this.isInHardwareMode = false,
    FloorRepository? floors,
    ListeningAreaRepository? listeningAreas,
    ZoneRepository? zones,
    SubZoneRepository? subZones,
    SourceSetRepository? sourceSets,
    HardwareRepository? hardware,
    FusionDeviceRepository? fusionDevices,
    FusionDeviceRepository? suggestedFusionDevices,
    AmplifierRepository? amplifiers,
    CircuitRepository? circuits,
    WiringConnectionRepository? wiringConnection,
    ProcessingBlockRepository? processingBlocks,
    RelationshipManager? relationships,
    ZoneFunctionRepository? zoneFunctions,
    PrioritySourceDataRepository? prioritySourceData,
    ScenesRepository? scenesRepository,
    SceneActionRepository? sceneActionRepository,
    SceneSetRepository? sceneSetRepository,
    GPIORepository? gpioRepository,
  }) : floors = floors ?? FloorRepository(),
       listeningAreas = listeningAreas ?? ListeningAreaRepository(),
       zones = zones ?? ZoneRepository(),
       subZones = subZones ?? SubZoneRepository(),
       sourceSets = sourceSets ?? SourceSetRepository(),
       hardware = hardware ?? HardwareRepository(),
       fusionDevices = fusionDevices ?? FusionDeviceRepository(),
       suggestedFusionDevices = suggestedFusionDevices ?? FusionDeviceRepository(),
       amplifiers = amplifiers ?? AmplifierRepository(),
       circuits = circuits ?? CircuitRepository(),
       wiringConnection = wiringConnection ?? WiringConnectionRepository(),
       processingBlocks = processingBlocks ?? ProcessingBlockRepository(),
       zoneFunctions = zoneFunctions ?? ZoneFunctionRepository(),
       relationships = relationships ?? RelationshipManager(),
       prioritySourceData = prioritySourceData ?? PrioritySourceDataRepository(),
       scenes = scenesRepository ?? ScenesRepository(),
       sceneActions = sceneActionRepository ?? SceneActionRepository(),
       sceneSets = sceneSetRepository ?? SceneSetRepository(),
       gpioConfig = gpioRepository ?? GPIORepository();

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
    SubZoneRepository? subZones,
    SourceSetRepository? sourceSets,
    HardwareRepository? hardware,
    FusionDeviceRepository? fusionDevices,
    FusionDeviceRepository? suggestedFusionDevices,
    AmplifierRepository? amplifiers,
    CircuitRepository? circuits,
    WiringConnectionRepository? wiringConnection,
    ProcessingBlockRepository? processingBlocks,
    RelationshipManager? relationships,
    ZoneFunctionRepository? zoneFunctions,
    bool? isInHardwareMode,
    PrioritySourceDataRepository? prioritySourceData,
    ScenesRepository? scenesRepository,
    SceneActionRepository? sceneActionRepository,
    SceneSetRepository? sceneSetRepository,
    GPIORepository? gpioRepository,
  }) {
    ProjectService projectService = ProjectService(
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
      subZones: subZones ?? this.subZones,
      sourceSets: sourceSets ?? this.sourceSets,
      hardware: hardware ?? this.hardware,
      fusionDevices: fusionDevices ?? this.fusionDevices,
      suggestedFusionDevices: suggestedFusionDevices ?? this.suggestedFusionDevices,
      amplifiers: amplifiers ?? this.amplifiers,
      circuits: circuits ?? this.circuits,
      wiringConnection: wiringConnection ?? this.wiringConnection,
      processingBlocks: processingBlocks ?? this.processingBlocks,
      relationships: relationships ?? this.relationships,
      isInHardwareMode: isInHardwareMode ?? this.isInHardwareMode,
      zoneFunctions: zoneFunctions ?? this.zoneFunctions,
      prioritySourceData: prioritySourceData ?? this.prioritySourceData,
      scenesRepository: scenesRepository ?? scenes,
      sceneActionRepository: sceneActionRepository ?? sceneActions,
      sceneSetRepository: sceneSetRepository ?? sceneSets,
      gpioRepository: gpioRepository ?? gpioConfig,
    );

    // Preserve undo/redo stacks
    projectService.undoStack = List.from(undoStack);
    projectService.redoStack = List.from(redoStack);
    return projectService;
  }

  /// -------------------
  /// JSON Serialization
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
      "isInHardwareMode": isInHardwareMode,
      "floors": floors.toJson((f) => f.toJson()),
      "listeningAreas": listeningAreas.toJson((a) => a.toJson()),
      "zones": zones.toJson((z) => z.toJson()),
      "subZones": subZones.toJson((sz) => sz.toJson()),
      "sourceSet": sourceSets.toJson((m) => m.toJson()),
      "hardware": hardware.toJson((HardwareComponent c) {
        if (c is Source) return c.toJson();
        if (c is Speaker) return c.toJson();
        if (c is FusionDsp) return c.toJson();
        if (c is FusionController) return c.toJson();
        if (c is Amplifier) return c.toJson();
        if (c is FusionEndpoints) return c.toJson();
        if (c is HardwareRack) return c.toJson();
        if (c is NetworkSwitch) return c.toJson();
        return (c as GenericHardwareComponent).toJson();
      }),
      "fusionDevices": fusionDevices.toJson((f) => f.toJson()),
      "suggestedFusionDevices": suggestedFusionDevices.toJson((f) => f.toJson()),
      "amplifiers": amplifiers.toJson((a) => a.toJson()),
      "circuits": circuits.toJson((c) => c.toJson()),
      "wiringConnection": wiringConnection.toJson((wc) => wc.toJson()),
      "processingBlocks": processingBlocks.toJson((pb) => pb.toJson()),
      "relationships": relationships.toJson(),
      "zoneFunctions": zoneFunctions.toJson((f) => f.toJson()),
      "prioritySourceData": prioritySourceData.toJson((psd) => psd.toJson()),
      "scenesRepository": scenes.toJson((s) => s.toJson()),
      "sceneActions": sceneActions.toJson((sa) => sa.toJson()),
      "sceneSetsRepository": sceneSets.toJson((ss) => ss.toJson()),
      "gpioConfig": gpioConfig.toJson((g) => g.toJson()),
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
      isInHardwareMode: json["isInHardwareMode"] ?? false,
    );

    service.floors.fromJsonList(json["floors"], (m) => FloorModel.fromJson(m), "id");
    service.listeningAreas.fromJsonList(json["listeningAreas"], (m) => ListeningArea.fromJson(m), "id");
    service.zones.fromJsonList(json["zones"], (m) => Zone.fromJson(m), "id");
    service.subZones.fromJsonList(json["subZones"], (m) => SubZone.fromJson(m), "id");
    service.sourceSets.fromJsonList(json["sourceSet"], (m) => SourceSet.fromJson(m), "id");

    service.hardware.fromJsonList(json["hardware"], (dynamic e) {
      final Map<String, dynamic> m = e as Map<String, dynamic>;
      if (m.containsKey('componentType') && m['componentType'] == 'source') {
        return Source.fromJson(m);
      } else if (m.containsKey('componentType') && m['componentType'] == 'speaker') {
        return Speaker.fromJson(m);
      } else if (m.containsKey('componentType') && m['componentType'] == 'fusionDsp') {
        return FusionDsp.fromJson(m);
      } else if (m.containsKey('componentType') && m['componentType'] == 'controller') {
        return FusionController.fromJson(m);
      } else if (m.containsKey('componentType') && m['componentType'] == 'fusionEndpoint') {
        return FusionEndpoints.fromJson(m);
      } else if (m.containsKey('componentType') && m['componentType'] == 'amplifier') {
        return Amplifier.fromJson(m);
      } else if (m.containsKey('componentType') && m['componentType'] == 'hardwareRack') {
        return HardwareRack.fromJson(m);
      } else if (m.containsKey('componentType') && m['componentType'] == 'networkSwitch') {
        return NetworkSwitch.fromJson(m);
      } else {
        return GenericHardwareComponent.fromJson(m);
      }
    }, "id");

    service.fusionDevices.fromJsonList(json["fusionDevices"], (m) => FusionDsp.fromJson(m), "id");
    service.suggestedFusionDevices.fromJsonList(json["suggestedFusionDevices"], (m) => FusionDsp.fromJson(m), "id");
    service.amplifiers.fromJsonList(json["amplifiers"], (m) => Amplifier.fromJson(m), "id");
    service.circuits.fromJsonList(json["circuits"], (m) => CircuitModel.fromJson(m), "id");
    service.wiringConnection.fromJsonList(json["wiringConnection"], (m) => WiringConnectionModel.fromJson(m), "id");
    service.processingBlocks.fromJsonList(json["processingBlocks"], (m) => ProcessingBlockModel.fromJson(m), "id");
    service.zoneFunctions.fromJsonList(json["zoneFunctions"], (m) => ZoneFunctions.fromJson(m), "id");
    service.prioritySourceData.fromJsonList(json["prioritySourceData"], (m) => PrioritySourceData.fromJson(m), "id");
    service.scenes.fromJsonList(json["scenesRepository"], (m) => SceneModel.fromJson(m), "id");
    service.sceneActions.fromJsonList(json["sceneActions"], (m) => SceneActionModel.fromJson(m), "id");
    service.sceneSets.fromJsonList(json["sceneSetsRepository"], (m) => SceneSetModel.fromJson(m), "id");
    service.gpioConfig.fromJsonList(json["gpioConfig"], (m) => GpioConfig.fromJson(m), "id");

    service.relationships.fromJson(json["relationships"]);

    return service;
  }
}
