import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';
import 'package:uuid/uuid.dart';

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
  Offset? pos;
  Offset? wiringPos;
  double? zAxis;
  final String assetImagePath;
  final LocationModel locationEntity;
  final double price;
  final int? equipmentLocationPosition;
  final String hardwareName;
  final bool lockListeningArea;
  final List<PortData> communicationPorts;
  final List<PortData> inputPortsData;
  final List<PortData> outputPortsData;
  final bool addedFromBuildingPage;

  static final Uuid _uuid = const Uuid();

  HardwareComponent({
    String? id,
    required this.name,
    this.pos,
    this.wiringPos,
    this.zAxis,
    required this.assetImagePath,
    required this.locationEntity,
    required this.price,
    required this.hardwareName,
    this.equipmentLocationPosition,
    HardwarePortData? portData,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
    this.lockListeningArea = false,
    this.communicationPorts = const [],
    required this.addedFromBuildingPage,
  }) : id = id ?? "HW${FusionUtils.shortStringUUID()}",
       inputPortsData =
           inputPortsData ??
           List<PortData>.generate(
             portData?.inputPorts ?? 0,
             (index) {
               return PortData(
                 id: FusionUtils.shortStringUUID(),
                 name: '${index + 1}',
                 type: portData?.inputPortType ?? PortType.analogInput,
                 portNumber: index + 1,
                 description: "${(portData?.inputPortType ?? PortType.analogInput).description} ${index + 1}",
                 position: portData?.portPosition ?? PortPosition.topLeft,
               );
             },
           ),
       outputPortsData =
           outputPortsData ??
           List<PortData>.generate(
             portData?.outputPorts ?? 0,
             (index) => PortData(
               id: FusionUtils.shortStringUUID(),
               name: '${index + 1}',
               description: "${(portData?.outputPortType ?? PortType.analogOutput).description} ${index + 1}",
               type: portData?.outputPortType ?? PortType.analogOutput,
               portNumber: index + 1,
               position: portData?.portPosition ?? PortPosition.topRight,
             ),
           );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HardwareComponent) return false;
    return id == other.id &&
        name == other.name &&
        equipmentLocationPosition == other.equipmentLocationPosition &&
        pos == other.pos &&
        wiringPos == other.wiringPos &&
        assetImagePath == other.assetImagePath &&
        locationEntity == other.locationEntity;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        pos.hashCode ^
        wiringPos.hashCode ^
        assetImagePath.hashCode ^
        locationEntity.hashCode ^
        equipmentLocationPosition.hashCode;
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
    int? equipmentLocationPosition,
    String? hardwareName,
    bool? lockListeningArea,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
    bool? addedFromBuildingPage,
  });
}

extension TotalPrice on List<HardwareComponent> {
  double get totalPrice {
    return fold(
      0.0,
      (double previousValue, HardwareComponent element) => previousValue + element.price,
    );
  }
}
