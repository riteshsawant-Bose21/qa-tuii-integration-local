import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller_page_model.dart';

class FusionController extends HardwareComponent {
  final String sku;

  /// Zone/SubZone IDs this controller is assigned to control
  final Set<String> assignedZoneIds;

  /// Persisted snapshot pages — scene-set selections and user-created snapshot pages.
  final List<ControllerPageModel> pages;

  /// Persisted message pages — checked message-player sources and their selected messages.
  final List<ControllerMessagePageModel> messagePages;

  /// Persisted schedule-tab settings.
  final ControllerSchedulePageConfig schedulePageConfig;

  /// Persisted display/settings-tab configuration (screen mode, saver, sleep time).
  final ControllerDisplayConfig displayConfig;

  FusionController({
    String? id,
    required super.name,
    super.pos,
    super.wiringPos,
    super.zAxis,
    required super.assetImagePath,
    LocationModel? locationEntity,
    required super.price,
    String? hardwareName,
    String? sku,
    super.lockListeningArea,
    super.portData,
    super.communicationPorts,
    super.inputPortsData,
    super.outputPortsData,
    super.equipmentLocationPosition,
    required super.addedFromBuildingPage,
    Set<String>? assignedZoneIds,
    List<ControllerPageModel>? pages,
    List<ControllerMessagePageModel>? messagePages,
    ControllerSchedulePageConfig? schedulePageConfig,
    ControllerDisplayConfig? displayConfig,
  }) : sku = sku ?? name,
       assignedZoneIds = assignedZoneIds ?? <String>{},
       pages = pages ?? <ControllerPageModel>[],
       messagePages = messagePages ?? <ControllerMessagePageModel>[],
       schedulePageConfig = schedulePageConfig ?? const ControllerSchedulePageConfig(),
       displayConfig = displayConfig ?? const ControllerDisplayConfig(),
       super(
         hardwareName: hardwareName ?? name,
         locationEntity: locationEntity ?? LocationModel(),
         id: id ?? "CONTROLLER${FusionUtils.shortStringUUID()}",
       );

  @override
  FusionController copyWith({
    String? id,
    String? name,
    Offset? pos,
    Offset? wiringPos,
    double? zAxis,
    String? assetImagePath,
    LocationModel? locationEntity,
    double? price,
    String? hardwareName,
    int? equipmentLocationPosition,
    String? sku,
    bool? lockListeningArea,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
    bool? addedFromBuildingPage,
    Set<String>? assignedZoneIds,
    List<ControllerPageModel>? pages,
    List<ControllerMessagePageModel>? messagePages,
    ControllerSchedulePageConfig? schedulePageConfig,
    ControllerDisplayConfig? displayConfig,
  }) {
    return FusionController(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      wiringPos: wiringPos ?? this.wiringPos,
      zAxis: zAxis ?? this.zAxis,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      locationEntity: locationEntity ?? this.locationEntity,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
      sku: sku ?? this.sku,
      lockListeningArea: lockListeningArea ?? this.lockListeningArea,
      communicationPorts: communicationPorts ?? this.communicationPorts,
      inputPortsData: inputPortsData ?? this.inputPortsData,
      outputPortsData: outputPortsData ?? this.outputPortsData,
      addedFromBuildingPage: addedFromBuildingPage ?? this.addedFromBuildingPage,
      equipmentLocationPosition: equipmentLocationPosition ?? this.equipmentLocationPosition,
      assignedZoneIds: assignedZoneIds ?? this.assignedZoneIds,
      pages: pages ?? this.pages,
      messagePages: messagePages ?? this.messagePages,
      schedulePageConfig: schedulePageConfig ?? this.schedulePageConfig,
      displayConfig: displayConfig ?? this.displayConfig,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'pos': pos != null ? <String, double>{'dx': pos!.dx, 'dy': pos!.dy} : null,
      'wiringPos': wiringPos != null ? {'x': wiringPos!.dx, 'y': wiringPos!.dy} : null,
      'zAxis': zAxis,
      'assetImagePath': assetImagePath,
      'locationEntity': locationEntity.toJson(),
      'price': price,
      'hardwareName': hardwareName,
      'sku': sku,
      'componentType': 'controller',
      'lockListeningArea': lockListeningArea,
      'communicationPorts': communicationPorts.map((PortData port) => port.toJson()).toList(),
      'outputPortsData': outputPortsData.map((PortData port) => port.toJson()).toList(),
      'inputPortsData': inputPortsData.map((PortData port) => port.toJson()).toList(),
      'addedFromBuildingPage': addedFromBuildingPage,
      'equipmentLocationPosition': equipmentLocationPosition,
      'assignedZoneIds': assignedZoneIds.toList(),
      'pages': pages.map((ControllerPageModel p) => p.toJson()).toList(),
      'messagePages': messagePages.map((ControllerMessagePageModel p) => p.toJson()).toList(),
      'schedulePageConfig': schedulePageConfig.toJson(),
      'displayConfig': displayConfig.toJson(),
    };
  }

  factory FusionController.fromJson(Map<String, dynamic> json) {
    return FusionController(
      id: json['id'] as String?,
      name: json['name'] as String,
      pos: json['pos'] != null ? Offset((json['pos']['dx'] as num).toDouble(), (json['pos']['dy'] as num).toDouble()) : null,
      wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['x'] as num).toDouble(), (json['wiringPos']['y'] as num).toDouble()) : null,
      zAxis: (json['zAxis'] as num?)?.toDouble() ?? 0.0,
      assetImagePath: json['assetImagePath'] as String,
      locationEntity: LocationModel.fromJson(json['locationEntity'] as Map<String, dynamic>),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      hardwareName: json['hardwareName'] as String? ?? json['name'] as String,
      sku: json['sku'] as String? ?? json['name'] as String,
      lockListeningArea: json['lockListeningArea'] as bool? ?? false,
      communicationPorts:
          (json['communicationPorts'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      outputPortsData: (json['outputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      inputPortsData: (json['inputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      addedFromBuildingPage: json['addedFromBuildingPage'] as bool? ?? false,
      equipmentLocationPosition: DeserializationUtil.intDeserializer.deserialize(json['equipmentLocationPosition']),
      assignedZoneIds: (json['assignedZoneIds'] as List<dynamic>?)?.map((dynamic e) => e as String).toSet() ?? <String>{},
      pages: _pagesFromJson(json),
      messagePages:
          (json['messagePages'] as List<dynamic>?)?.map((dynamic e) => ControllerMessagePageModel.fromJson(Map<String, dynamic>.from(e as Map))).toList() ??
          <ControllerMessagePageModel>[],
      schedulePageConfig: json['schedulePageConfig'] != null
          ? ControllerSchedulePageConfig.fromJson(Map<String, dynamic>.from(json['schedulePageConfig'] as Map))
          : const ControllerSchedulePageConfig(),
      displayConfig: json['displayConfig'] != null
          ? ControllerDisplayConfig.fromJson(Map<String, dynamic>.from(json['displayConfig'] as Map))
          : const ControllerDisplayConfig(),
    );
  }

  static List<ControllerPageModel> _pagesFromJson(Map<String, dynamic> json) {
    // New key: 'pages'
    if (json['pages'] != null) {
      return (json['pages'] as List<dynamic>).map((dynamic e) => ControllerPageModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    // Backward compat: old 'snapshotPagesData' key — migrate as snapshotPage type
    if (json['snapshotPagesData'] != null) {
      return (json['snapshotPagesData'] as List<dynamic>).map((dynamic e) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(e as Map);
        return ControllerPageModel(
          id: m['id'] as String,
          type: ControllerPageType.snapshotPage,
          name: m['name'] as String,
          snapshotIds: (m['snapshotIds'] as List<dynamic>?)?.cast<String>() ?? <String>[],
        );
      }).toList();
    }
    return <ControllerPageModel>[];
  }
}
