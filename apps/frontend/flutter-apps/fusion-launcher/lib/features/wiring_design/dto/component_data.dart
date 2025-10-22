import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../util/canvas_util.dart';

part 'component_port.dart';

abstract class ComponentData {
  String get id;
  final String? image;
  final String label;
  final List<ComponentPort> inputPorts;
  final List<ComponentPort> outputPorts;
  final List<ComponentPort> comPorts;

  ComponentData({
    this.image,
    required this.label,
    required this.comPorts,
    required this.inputPorts,
    required this.outputPorts,
  });

  String get type;

  Size get size;
  Offset get portOffset;
  double get portRadius;

}

class DeviceSchematicComponentData extends ComponentData {
  final HardwareComponent data;
  DeviceSchematicComponentData({
    super.image,
    required super.label,
    required super.comPorts,
    required super.inputPorts,
    required super.outputPorts,
    required this.data,
  });

  static DeviceSchematicComponentData from(HardwareComponent hardware) {
    return DeviceSchematicComponentData(
      image: hardware.assetImagePath,
      label: hardware.name,
      comPorts: <ComponentPort>[],
      inputPorts: List<ComponentPort>.generate(
        Random().nextInt(4) + 3,
        (int index) => ComponentPort.input(
          data: index.toString(),
          label: (index + 1).toString(),
        ),
      ),
      outputPorts: List<ComponentPort>.generate(
        Random().nextInt(4) + 3,
        (int index) => ComponentPort.output(
          data: index.toString(),
          label: (index + 1).toString(),
        ),
      ),
      data: hardware,
    );
  }

  @override
  Size get size {
    const Size headingHeight = Size(300, WiringViewConstants.headingHeight);
    Size cSize = headingHeight; // lable height
    final int max2 = max(inputPorts.length, outputPorts.length);
    cSize += Offset(
      0,
      max2 * WiringViewConstants.portDimension +
          (max2 + 2) * WiringViewConstants.portSpacing,
    );

    if (comPorts.isNotEmpty) {
      cSize += const Offset(0, 100);
    }
    return cSize;
  }

  @override
  Offset get portOffset => const Offset(0, WiringViewConstants.headingHeight);
  @override
  double get portRadius => WiringViewConstants.portRadius;

  @override
  String get id => data.id;

  @override
  String get type => 'device_schematic';
}

class SourceComponentData extends ComponentData {
  final Source source;
  SourceComponentData({
    super.image,
    required super.label,
    required super.comPorts,
    required super.inputPorts,
    required super.outputPorts,
    required this.source,
  });

  static SourceComponentData from(Source source) {
    return SourceComponentData(
      image: source.assetImagePath,
      label: source.name,
      comPorts: <ComponentPort>[],
      inputPorts: <ComponentPort>[],
      outputPorts: <ComponentPort>[
        ComponentPort.output(data: "0", label: "0"),
      ],
      source: source,
    );
  }

  @override
  String get id => source.id;
  @override
  Size get size => const Size(100, 100);

  @override
  Offset get portOffset => Offset(0, size.height / 2 - portRadius);
  @override
  double get portRadius => WiringViewConstants.portRadius / 2;

  @override
  String get type => 'source';
}

class ZoneComponentData extends ComponentData {
  final Zone zone;
  ZoneComponentData({
    super.image,
    required super.label,
    required super.comPorts,
    required super.inputPorts,
    required super.outputPorts,
    required this.zone,
  });
  static ZoneComponentData from(Zone zone) {
    return ZoneComponentData(
      // image: source.assetImagePath,
      label: zone.name,
      comPorts: <ComponentPort>[],
      inputPorts: <ComponentPort>[],
      outputPorts: <ComponentPort>[
        // ComponentPort(data: 0, label: "0"),
      ],
      zone: zone,
    );
  }

  @override
  String get id => zone.id;

  @override
  Offset get portOffset => Offset.zero;
  @override
  Size get size => const Size(160, 30);
  @override
  double get portRadius => 0;
  @override
  String get type => 'zone';
}

class SpeakerComponentData extends ComponentData {
  final Speaker speaker;
  SpeakerComponentData({
    super.image,
    required super.label,
    required super.comPorts,
    required super.inputPorts,
    required super.outputPorts,
    required this.speaker,
  });
  static SpeakerComponentData from(Speaker speaker) {
    return SpeakerComponentData(
      image: speaker.assetImagePath,
      label: speaker.name,
      comPorts: <ComponentPort>[],
      inputPorts: <ComponentPort>[ComponentPort.input(data: "0", label: "0")],
      outputPorts: <ComponentPort>[],
      speaker: speaker,
    );
  }

  @override
  String get id => speaker.id;
  @override
  Size get size => const Size(100, 100);
  @override
  Offset get portOffset => Offset(0, size.height / 2 - portRadius);
  @override
  double get portRadius => WiringViewConstants.portRadius / 2;

  @override
  String get type => 'speaker';
}
