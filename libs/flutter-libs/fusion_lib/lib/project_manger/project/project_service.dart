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
  final double minSPL;
  final double maxSPL;
  bool isInControlMode;
  bool isInHardwareMode = false;
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
  final DateTime? lastUploadedAt;
  final bool isDeleted;
  final bool isCloudInstance;
  final ProjectMetaData metadata;

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
  final EquipLocationRepository equipLocations;
  final ScenesRepository snapshots;
  final SceneActionRepository sceneActions;
  final SceneSetRepository sceneSets;
  final GPIORepository gpioConfigs;
  final SchedulerRepository schedulerConfig;
  final EventsRepository events;
  final MediaFileRepository mediaFiles;

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
    required this.minSPL,
    required this.maxSPL,
    this.isInControlMode = false,
    this.isInHardwareMode = false,
    this.application,
    this.budget,
    this.description,
    this.environmentType,
    this.isArchived = false,
    this.isStarred = false,
    this.isDeleted = false,
    this.lockedByUser,
    this.projectFileUrl,
    this.projectPhase,
    this.thumbnailUrl,
    this.venue,
    this.lastUploadedAt,
    this.isCloudInstance = false,
    required this.metadata,

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
    EquipLocationRepository? equipLocations,
    ScenesRepository? scenesRepository,
    SceneActionRepository? sceneActionRepository,
    SceneSetRepository? sceneSetRepository,
    GPIORepository? gpioRepository,
    SchedulerRepository? schedulerConfig,
    EventsRepository? events,
    MediaFileRepository? mediaFiles,
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
       equipLocations = equipLocations ?? EquipLocationRepository(),
       snapshots = scenesRepository ?? ScenesRepository(),
       sceneActions = sceneActionRepository ?? SceneActionRepository(),
       sceneSets = sceneSetRepository ?? SceneSetRepository(),
       gpioConfigs = gpioRepository ?? GPIORepository(),
       schedulerConfig = schedulerConfig ?? SchedulerRepository(),
       events = events ?? EventsRepository(),
       mediaFiles = mediaFiles ?? MediaFileRepository();

  ProjectService updateVip(String? vip) {
    ProjectService projectService = ProjectService(
      id: id,
      name: name,
      projectName: projectName,
      colors: colors,
      virtualIP: vip,
      currentFloorIndex: currentFloorIndex,
      droResponse: droResponse,
      createdAt: createdAt,
      updatedAt: updatedAt,
      minSPL: minSPL,
      maxSPL: maxSPL,
      isInControlMode: isInControlMode,
      application: application,
      budget: budget,
      description: description,
      environmentType: environmentType,
      isArchived: isArchived,
      isStarred: isStarred,
      lockedByUser: lockedByUser,
      projectFileUrl: projectFileUrl,
      projectPhase: projectPhase,
      thumbnailUrl: thumbnailUrl,
      venue: venue,
      isDeleted: isDeleted,
      lastUploadedAt: lastUploadedAt,
      floors: floors,
      listeningAreas: listeningAreas,
      zones: zones,
      subZones: subZones,
      sourceSets: sourceSets,
      hardware: hardware,
      fusionDevices: fusionDevices,
      suggestedFusionDevices: suggestedFusionDevices,
      amplifiers: amplifiers,
      circuits: circuits,
      wiringConnection: wiringConnection,
      processingBlocks: processingBlocks,
      relationships: relationships,
      isInHardwareMode: isInHardwareMode,
      isCloudInstance: isCloudInstance,
      zoneFunctions: zoneFunctions,
      prioritySourceData: prioritySourceData,
      equipLocations: equipLocations,
      scenesRepository: snapshots,
      sceneActionRepository: sceneActions,
      sceneSetRepository: sceneSets,
      gpioRepository: gpioConfigs,
      schedulerConfig: schedulerConfig,
      events: events,
      mediaFiles: mediaFiles,
      metadata: metadata,
    );

    // Preserve undo/redo stacks
    projectService.undoStack = List.from(undoStack);
    projectService.redoStack = List.from(redoStack);

    return projectService;
  }

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
    double? minSPL,
    double? maxSPL,
    bool? isInControlMode,
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
    bool? isDeleted,
    DateTime? lastUploadedAt,
    bool? isCloudInstance,
    ProjectMetaData? metadata,
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
    EquipLocationRepository? equipLocations,
    ScenesRepository? scenesRepository,
    SceneActionRepository? sceneActionRepository,
    SceneSetRepository? sceneSetRepository,
    GPIORepository? gpioRepository,
    SchedulerRepository? schedulerConfig,
    EventsRepository? events,
    MediaFileRepository? mediaFiles,
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
      minSPL: minSPL ?? this.minSPL,
      maxSPL: maxSPL ?? this.maxSPL,
      isInControlMode: isInControlMode ?? this.isInControlMode,
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
      isDeleted: isDeleted ?? this.isDeleted,
      lastUploadedAt: lastUploadedAt ?? this.lastUploadedAt,
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
      isCloudInstance: isCloudInstance ?? this.isCloudInstance,
      zoneFunctions: zoneFunctions ?? this.zoneFunctions,
      prioritySourceData: prioritySourceData ?? this.prioritySourceData,
      equipLocations: equipLocations ?? this.equipLocations,
      scenesRepository: scenesRepository ?? snapshots,
      sceneActionRepository: sceneActionRepository ?? sceneActions,
      sceneSetRepository: sceneSetRepository ?? sceneSets,
      gpioRepository: gpioRepository ?? gpioConfigs,
      schedulerConfig: schedulerConfig ?? this.schedulerConfig,
      events: events ?? this.events,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      metadata: metadata ?? this.metadata,
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
      "colors": colors.map((c) => '0x${c.toARGB32().toRadixString(16).padLeft(8, '0')}').toList(),
      "virtualIP": virtualIP,
      "currentFloorIndex": currentFloorIndex,
      "droResponse": droResponse,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "minSPL": minSPL,
      "maxSPL": maxSPL,
      "isInControlMode": isInControlMode,
      "isInHardwareMode": isInHardwareMode,
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
      "is_deleted": isDeleted,
      "lastUploadedAt": lastUploadedAt?.toIso8601String(),
      "isCloudInstance": isCloudInstance,
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
      'equipLocations': equipLocations.toJson((el) => el.toJson()),
      "snapshots": snapshots.toJson((s) => s.toJson()),
      "sceneActions": sceneActions.toJson((sa) => sa.toJson()),
      "sceneSets": sceneSets.toJson((ss) => ss.toJson()),
      "gpioConfig": gpioConfigs.toJson((g) => g.toJson()),
      "schedulerConfig": schedulerConfig.toJson((s) => s.toJson()),
      "events": events.toJson((e) => e.toJson()),
      "mediaFiles": mediaFiles.toJson((m) => m.toJson()),
      'metadata': metadata.toJson(),
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
      minSPL: (json["minSPL"] as num).toDouble(),
      maxSPL: (json["maxSPL"] as num).toDouble(),
      isInControlMode: json["isInControlMode"] ?? false,
      isInHardwareMode: json["isInHardwareMode"] ?? false,
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
      isDeleted: json["is_deleted"] ?? false,
      lastUploadedAt: json["lastUploadedAt"] != null ? DateTime.parse(json["lastUploadedAt"]) : null,
      isCloudInstance: json["isCloudInstance"] ?? false,
      metadata: json['metadata'] != null ? ProjectMetaData.fromJson(json['metadata'] as Map<String, dynamic>) : ProjectMetaData.empty(),
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
    service.equipLocations.fromJsonList(json['equipLocations'], (m) => EquipLocation.fromJson(m), 'id');
    service.snapshots.fromJsonList(json["snapshots"], (m) => SnapshotsModel.fromJson(m), "id");
    service.sceneActions.fromJsonList(json["sceneActions"], (m) => SceneActionModel.fromJson(m), "id");
    service.sceneSets.fromJsonList(json["sceneSets"], (m) => SceneSetModel.fromJson(m), "id");
    service.gpioConfigs.fromJsonList(json["gpioConfig"], (m) => GpioConfig.fromJson(m), "id");
    service.schedulerConfig.fromJsonList(json["schedulerConfig"], (m) => ScheduleConfig.fromJson(m), "id");
    service.events.fromJsonList(json["events"], (m) => FusionEvent.fromJson(m), "id");
    service.mediaFiles.fromJsonList(json["mediaFiles"], (m) => MediaFileModel.fromJson(m), "id");

    service.relationships.fromJson(json["relationships"]);

    return service;
  }
}
