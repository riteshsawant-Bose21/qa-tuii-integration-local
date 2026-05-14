import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

// ── Connection type for third-party output devices ────────────────────────

enum OutputDeviceConnectionType {
  analogOutput,
  usbOutput,
  aes67Stream;

  String get displayName => switch (this) {
    OutputDeviceConnectionType.analogOutput => 'Analog Output',
    OutputDeviceConnectionType.usbOutput => 'USB Output',
    OutputDeviceConnectionType.aes67Stream => 'AES67 Stream',
  };

  static OutputDeviceConnectionType fromString(String? value) {
    if (value == null || value.isEmpty) return OutputDeviceConnectionType.analogOutput;
    return OutputDeviceConnectionType.values.firstWhere(
      (OutputDeviceConnectionType e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => OutputDeviceConnectionType.analogOutput,
    );
  }
}

// ── Category / purpose of the third-party device ─────────────────────────

enum OutputDeviceType {
  mediaRecorder,
  laptopOrPC,
  mixer,
  localOutput,
  monitorOutput,
  hearingAssistance,
  poweredSpeaker,
  externalSystem,
  genericOutput,
  genericAmplifier;

  String get displayName => switch (this) {
    OutputDeviceType.mediaRecorder => 'Media Recorder',
    OutputDeviceType.laptopOrPC => 'Laptop/PC',
    OutputDeviceType.mixer => 'Mixer',
    OutputDeviceType.localOutput => 'Local Output',
    OutputDeviceType.monitorOutput => 'Monitor Output',
    OutputDeviceType.hearingAssistance => 'Hearing Assistance',
    OutputDeviceType.poweredSpeaker => 'Powered Speaker',
    OutputDeviceType.externalSystem => 'External System',
    OutputDeviceType.genericOutput => 'Generic Output',
    OutputDeviceType.genericAmplifier => 'Generic Amplifier',
  };

  static OutputDeviceType fromString(String? value) {
    if (value == null || value.isEmpty) return OutputDeviceType.genericOutput;
    return OutputDeviceType.values.firstWhere(
      (OutputDeviceType e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => OutputDeviceType.genericOutput,
    );
  }
}

// ── OutputDevice model ────────────────────────────────────────────────────

/// Represents a third-party (non-ecosystem) output device connected to the
/// Fusion system — e.g. an external brand speaker, amplifier, or recorder.
class OutputDevice extends HardwareComponent {
  final OutputDeviceType outputDeviceType;
  final OutputDeviceConnectionType connectionType;
  final AudioChannel audioChannel;

  OutputDevice({
    String? id,
    required super.locationEntity,
    required super.name,
    super.pos,
    super.wiringPos,
    super.zAxis,
    required this.outputDeviceType,
    required this.connectionType,
    required this.audioChannel,
    super.image = '',
    required super.price,
    String? hardwareName,
    super.lockListeningArea,
    super.portData,
    super.equipmentLocationPosition,
    super.communicationPorts,
    super.inputPortsData,
    super.outputPortsData,
    required super.addedFromBuildingPage,
  }) : super(
         hardwareName: hardwareName ?? name,
         id: id ?? 'OUTPUTDEVICE${FusionUtils.shortStringUUID()}',
       );

  @override
  OutputDevice copyWith({
    String? id,
    String? name,
    Offset? pos,
    Offset? wiringPos,
    double? zAxis,
    OutputDeviceType? outputDeviceType,
    OutputDeviceConnectionType? connectionType,
    AudioChannel? audioChannel,
    String? image,
    LocationModel? locationEntity,
    double? price,
    String? hardwareName,
    bool? lockListeningArea,
    int? equipmentLocationPosition,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
    bool? addedFromBuildingPage,
  }) {
    return OutputDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      wiringPos: wiringPos ?? this.wiringPos,
      zAxis: zAxis ?? this.zAxis,
      outputDeviceType: outputDeviceType ?? this.outputDeviceType,
      connectionType: connectionType ?? this.connectionType,
      audioChannel: audioChannel ?? this.audioChannel,
      image: image ?? this.image,
      locationEntity: locationEntity ?? this.locationEntity,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
      lockListeningArea: lockListeningArea ?? this.lockListeningArea,
      communicationPorts: communicationPorts ?? this.communicationPorts,
      inputPortsData: inputPortsData ?? this.inputPortsData,
      outputPortsData: outputPortsData ?? this.outputPortsData,
      addedFromBuildingPage: addedFromBuildingPage ?? this.addedFromBuildingPage,
      equipmentLocationPosition: equipmentLocationPosition ?? this.equipmentLocationPosition,
    );
  }

  factory OutputDevice.fromJson(Map<String, dynamic> json) {
    return OutputDevice(
      id: json['id'],
      name: json['name'],
      pos: json['pos'] != null ? Offset((json['pos']['dx'] as num).toDouble(), (json['pos']['dy'] as num).toDouble()) : null,
      wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['dx'] as num).toDouble(), (json['wiringPos']['dy'] as num).toDouble()) : null,
      outputDeviceType: OutputDeviceType.fromString(json['outputDeviceType']),
      connectionType: OutputDeviceConnectionType.fromString(json['connectionType']),
      audioChannel: AudioChannel.fromJson(json['audioChannel']) ?? AudioChannel.mono,
      image: json['image'] ?? '',
      locationEntity: LocationModel.fromJson(json['locationEntity']),
      price: double.tryParse("${json['price']}") ?? 0.0,
      hardwareName: json['hardwareName'] ?? '',
      zAxis: double.tryParse("${json['zAxis']}") ?? 0.0,
      lockListeningArea: json['lockListeningArea'] as bool? ?? false,
      communicationPorts: List.from(json['communicationPorts'] ?? []).map((dynamic e) => PortData.fromJson(e)).toList(),
      outputPortsData: List.from(json['outputPortsData'] ?? []).map((dynamic e) => PortData.fromJson(e)).toList(),
      inputPortsData: List.from(json['inputPortsData'] ?? []).map((dynamic e) => PortData.fromJson(e)).toList(),
      addedFromBuildingPage: json['addedFromBuildingPage'] as bool? ?? false,
      equipmentLocationPosition: DeserializationUtil.intDeserializer.deserialize(json['equipmentLocationPosition']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'pos': pos != null ? <String, double>{'dx': pos!.dx, 'dy': pos!.dy} : null,
      'wiringPos': wiringPos != null ? <String, double>{'dx': wiringPos!.dx, 'dy': wiringPos!.dy} : null,
      'outputDeviceType': outputDeviceType.name,
      'connectionType': connectionType.name,
      'audioChannel': audioChannel.name,
      'image': image,
      'componentType': 'outputDevice',
      'locationEntity': locationEntity.toJson(),
      'price': price,
      'hardwareName': hardwareName,
      'zAxis': zAxis,
      'lockListeningArea': lockListeningArea,
      'communicationPorts': communicationPorts.map((PortData port) => port.toJson()).toList(),
      'outputPortsData': outputPortsData.map((PortData port) => port.toJson()).toList(),
      'inputPortsData': inputPortsData.map((PortData port) => port.toJson()).toList(),
      'addedFromBuildingPage': addedFromBuildingPage,
      'equipmentLocationPosition': equipmentLocationPosition,
    };
  }
}
