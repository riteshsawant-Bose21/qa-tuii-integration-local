import 'dart:math';
import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

import '../util/canvas_util.dart';

abstract class ComponentData {
  String get id;
  final String? image;
  final String label;
  final List<InputComponentPort> inputPorts;
  final List<OutputComponentPort> outputPorts;
  final List<ComComponentPort> comPorts;

  ComponentData({
    this.image,
    required this.label,
    required this.comPorts,
    required this.inputPorts,
    required this.outputPorts,
  });

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
      comPorts: <ComComponentPort>[],
      inputPorts: List<InputComponentPort>.generate(
        Random().nextInt(4) + 3,
        (int index) =>
            InputComponentPort(data: index, label: (index + 1).toString()),
      ),
      outputPorts: List<OutputComponentPort>.generate(
        Random().nextInt(4) + 3,
        (int index) =>
            OutputComponentPort(data: index, label: (index + 1).toString()),
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
      comPorts: <ComComponentPort>[],
      inputPorts: <InputComponentPort>[],
      outputPorts: <OutputComponentPort>[
        OutputComponentPort(data: 0, label: "0"),
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
      comPorts: <ComComponentPort>[],
      inputPorts: <InputComponentPort>[],
      outputPorts: <OutputComponentPort>[
        // OutputComponentPort(data: 0, label: "0"),÷
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
      comPorts: <ComComponentPort>[],
      inputPorts: <InputComponentPort>[InputComponentPort(data: 0, label: "0")],
      outputPorts: <OutputComponentPort>[],
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
}

abstract class ComponentPort {
  final String? image;
  final String? label;
  final String type;
  final List<String> compatibleTypes;

  ComponentPort({
    this.image,
    this.label,
    required this.type,
    required this.compatibleTypes,
  });
}

class InputComponentPort extends ComponentPort {
  final int data;
  InputComponentPort({
    required this.data,
    super.image,
    super.label,
    super.type = 'input',
    super.compatibleTypes = const <String>['output'],
  });
}

class OutputComponentPort extends ComponentPort {
  final int data;
  OutputComponentPort({
    required this.data,
    super.image,
    super.label,
    super.type = 'output',
    super.compatibleTypes = const <String>['input'],
  });
}

class ComComponentPort extends ComponentPort {
  final int data;
  ComComponentPort({
    required this.data,
    super.image,
    super.label,
    required super.type,
    required super.compatibleTypes,
  });
}
