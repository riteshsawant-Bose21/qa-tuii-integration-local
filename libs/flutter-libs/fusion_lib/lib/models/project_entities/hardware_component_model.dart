import 'dart:math';
import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';
import 'package:uuid/uuid.dart';

import 'location_model.dart';

class HardwarePortData {
  final int inputPorts;
  final int outputPorts;
  final PortType inputPortType;
  final PortType outputPortType;
  final List<PortType> compatibleInputTypes;
  final List<PortType> compatibleOutputTypes;
  final PortPosition portPosition;

  HardwarePortData({
    this.inputPorts = 0,
    this.outputPorts = 0,
    this.inputPortType = PortType.analogInput,
    this.outputPortType = PortType.analogOutput,
    this.compatibleInputTypes = const [],
    this.compatibleOutputTypes = const [],
    this.portPosition = PortPosition.topLeft,
  });
}

/// Base class for any hardware component
abstract class HardwareComponent {
  final String id;
  final String name;
  Offset pos;
  Offset? wiringPos;
  double zAxis;
  final String assetImagePath;
  final LocationModel locationEntity;
  final double price;
  final String hardwareName;
  final bool lockListeningArea;
  final List<PortData> communicationPorts;
  final List<PortData> inputPortsData;
  final List<PortData> outputPortsData;

  static final Uuid _uuid = const Uuid();

  HardwareComponent({
    String? id,
    required this.name,
    Offset? pos,
    this.wiringPos,
    this.zAxis = 0,
    required this.assetImagePath,
    required this.locationEntity,
    required this.price,
    required this.hardwareName,
    HardwarePortData? portData,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
    this.lockListeningArea = false,
    this.communicationPorts = const [],
  }) : id = id ?? FusionUtils.shortStringUUID(),
       pos = pos ?? const Offset(0, 0),
       inputPortsData =
           inputPortsData ??
           List<PortData>.generate(
             portData?.inputPorts ?? 0,
             (index) => PortData(
               id: FusionUtils.shortStringUUID(),
               name: 'Input ${index + 1}',
               type: portData?.inputPortType ?? PortType.analogInput,
               portNumber: index + 1,
               position: portData?.portPosition ?? PortPosition.topLeft,
               compatibleTypes: portData?.compatibleInputTypes ?? [],
             ),
           ),
       outputPortsData =
           outputPortsData ??
           List<PortData>.generate(
             portData?.outputPorts ?? 0,
             (index) => PortData(
               id: _uuid.v4(),
               name: 'Output ${index + 1}',
               type: portData?.outputPortType ?? PortType.analogOutput,
               portNumber: index + 1,
               position: portData?.portPosition ?? PortPosition.topRight,
               compatibleTypes: portData?.compatibleOutputTypes ?? [],
             ),
           );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HardwareComponent) return false;
    return id == other.id && name == other.name && pos == other.pos && assetImagePath == other.assetImagePath && locationEntity == other.locationEntity;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ pos.hashCode ^ assetImagePath.hashCode ^ locationEntity.hashCode;
  }

  HardwareComponent copyWith({
    String? id,
    String? name,
    Offset? pos,
    Offset? wiringPos,
    double? zAxis,
    String? assetImagePath,
    LocationModel? locationEntity,
    double? price,
    String? hardwareName,
    bool? lockListeningArea,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
  });
}

extension TotalPrice on List<HardwareComponent> {
  double get totalPrice {
    return fold(0.0, (double previousValue, HardwareComponent element) => previousValue + element.price);
  }
}
