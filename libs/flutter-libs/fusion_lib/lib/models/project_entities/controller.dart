import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller_page_model.dart';

/// A wall-controller hardware component.
///
/// Per-controller pages and zone assignments are stored in repositories /
/// relationships on [ProjectService].  Display settings and schedule-tab UI
/// preferences live directly on this model.
class FusionController extends HardwareComponent {
  final String sku;

  /// Screen mode / saver / sleep-time settings for the physical controller.
  final ControllerDisplayConfig displayConfig;

  /// Whether "Show upcoming items" is checked in the Schedule tab.
  final bool showUpcoming;

  /// Schedule filter radio-button selection: 'none' | 'all' | 'selected'.
  final String scheduleDisplayMode;

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
    ControllerDisplayConfig? displayConfig,
    bool showUpcoming = false,
    String scheduleDisplayMode = 'all',
  }) : sku = sku ?? name,
       displayConfig = displayConfig ?? const ControllerDisplayConfig(),
       showUpcoming = showUpcoming,
       scheduleDisplayMode = scheduleDisplayMode,
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
    ControllerDisplayConfig? displayConfig,
    bool? showUpcoming,
    String? scheduleDisplayMode,
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
      displayConfig: displayConfig ?? this.displayConfig,
      showUpcoming: showUpcoming ?? this.showUpcoming,
      scheduleDisplayMode: scheduleDisplayMode ?? this.scheduleDisplayMode,
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
      'displayConfig': displayConfig.toJson(),
      'showUpcoming': showUpcoming,
      'scheduleDisplayMode': scheduleDisplayMode,
    };
  }

  factory FusionController.fromJson(Map<String, dynamic> json) {
    // ── Display config ──────────────────────────────────────────────────────
    final ControllerDisplayConfig displayConfig = json['displayConfig'] != null
        ? ControllerDisplayConfig.fromJson(Map<String, dynamic>.from(json['displayConfig'] as Map))
        : const ControllerDisplayConfig();

    // ── Schedule fields — with backward compat from old 'schedulePageConfig' ─
    final Map<String, dynamic>? legacySched = json['schedulePageConfig'] != null ? Map<String, dynamic>.from(json['schedulePageConfig'] as Map) : null;
    final bool showUpcoming = json['showUpcoming'] as bool? ?? legacySched?['showUpcoming'] as bool? ?? false;
    final String scheduleDisplayMode = json['scheduleDisplayMode'] as String? ?? legacySched?['displayMode'] as String? ?? 'all';

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
      displayConfig: displayConfig,
      showUpcoming: showUpcoming,
      scheduleDisplayMode: scheduleDisplayMode,
    );
  }
}
