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
  LocationModel? get location;
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

  @override
  LocationModel? get location => data.locationEntity;
  static DeviceSchematicComponentData from(HardwareComponent hardware) {
    return DeviceSchematicComponentData(
      image: hardware.assetImagePath,
      label: hardware.name,
      comPorts:
          hardware.communicationPorts
              .map(
                (PortData e) => ComponentPort.fromPortData(
                  e,
                  // data: e.id,
                  // label: e.name,
                  // type: e.type,
                  // image: switch (e.type) {
                  //   PortType.ethernet =>
                  //     'assets/icons/wiring_ports/ethernet.png',
                  //   PortType.wifi => 'assets/icons/wiring_ports/wifi.png',
                  //   PortType.ble => 'assets/icons/wiring_ports/bluetooth.png',
                  //   PortType.hdmi => 'assets/icons/wiring_ports/hdmi.png',
                  //   PortType.usb => 'assets/icons/wiring_ports/usb.png',
                  //   PortType.audioJack =>
                  //     'assets/icons/wiring_ports/audio_jack.png',
                  //   _ => null,
                  // },
                  // position: e.position,
                  // compatibleTypes: e.compatibleTypes,
                ),
              )
              .toList(),
      inputPorts:
          hardware.inputPortsData
              .map(
                (PortData e) => ComponentPort.fromPortData(
                  e,
                  // data: e.id,
                  // label: e.name,
                  // type: e.type,
                  // compatibleTypes: e.compatibleTypes,
                ),
              )
              .toList(),
      outputPorts:
          hardware.outputPortsData
              .map(
                (PortData e) => ComponentPort.fromPortData(
                  e,
                  // data: e.id,
                  // label: e.name,
                  // type: e.type,
                  // compatibleTypes: e.compatibleTypes,
                ),
              )
              .toList(),

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
      final int extraHeight = max(
        comPorts
            .where((ComponentPort e) => e.position == PortPosition.bottomLeft)
            .length,
        comPorts
            .where((ComponentPort e) => e.position == PortPosition.bottomRight)
            .length,
      );
      cSize += Offset(0, extraHeight * WiringViewConstants.portDimension);

      cSize += Offset(
        0,
        max(1, extraHeight - 1) * WiringViewConstants.portSpacing,
      );
      final int hasFooterLeft =
          comPorts
              .where(
                (ComponentPort e) => e.position == PortPosition.footerLeft,
              )
              .length;
      final int hasFooterCenter =
          comPorts
              .where(
                (ComponentPort e) => e.position == PortPosition.footerCenter,
              )
              .length;
      final int hasFooterRight =
          comPorts
              .where(
                (ComponentPort e) => e.position == PortPosition.footerRight,
              )
              .length;
      if ((hasFooterLeft + hasFooterRight + hasFooterCenter) > 0) {
        double comPortWidth = WiringViewConstants.portSpacing;
        if (hasFooterLeft > 0) {
          comPortWidth +=
              hasFooterLeft * WiringViewConstants.comPortWidth +
              (hasFooterLeft) * WiringViewConstants.portSpacing;
        } else {
          comPortWidth += WiringViewConstants.comPortWidth;
        }
        if (hasFooterCenter > 0) {
          comPortWidth +=
              hasFooterCenter * WiringViewConstants.comPortWidth +
              (hasFooterCenter) * WiringViewConstants.portSpacing;
        } else {
          comPortWidth += WiringViewConstants.comPortWidth;
        }
        if (hasFooterRight > 0) {
          comPortWidth +=
              hasFooterRight * WiringViewConstants.comPortWidth +
              (hasFooterRight) * WiringViewConstants.portSpacing;
        } else {
          comPortWidth += WiringViewConstants.comPortWidth;
        }
        cSize += Offset(
          max(
                cSize.width,
                comPortWidth,
              ) -
              cSize.width,
          100,
        );
      }
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
  @override
  LocationModel? get location => source.locationEntity;
  static SourceComponentData from(Source source) {
    return SourceComponentData(
      image: source.assetImagePath,
      label: source.name,
      comPorts: <ComponentPort>[],
      inputPorts: <ComponentPort>[],
      outputPorts:
          source.outputPortsData
              .map(
                (PortData e) => ComponentPort.fromPortData(
                  e,
                  // data: e.id,
                  // label: e.name,
                  // type: e.type,
                  // position: e.position,
                  // index: e.portNumber,
                  // compatibleTypes: e.compatibleTypes,
                ),
              )
              .toList(),
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
  LocationModel? get location => null;
  @override
  Offset get portOffset => Offset.zero;
  @override
  Size get size => const Size(200, 30);
  @override
  double get portRadius => 0;
  @override
  String get type => 'zone';
}

class SubZoneComponentData extends ComponentData {
  final SubZone zone;
  SubZoneComponentData({
    super.image,
    required super.label,
    required super.comPorts,
    required super.inputPorts,
    required super.outputPorts,
    required this.zone,
  });
  static SubZoneComponentData from(SubZone zone) {
    return SubZoneComponentData(
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
  LocationModel? get location => null;
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

class CircuitComponentData extends ComponentData {
  final List<ComponentData> speakers;
  final CircuitModel circuit;
  CircuitComponentData({
    super.image,
    required super.label,
    required super.comPorts,
    required super.inputPorts,
    required super.outputPorts,
    required this.circuit,
    required this.speakers,
  });
  static CircuitComponentData from(
    CircuitModel zone,
    List<ComponentData> speakers,
  ) {
    return CircuitComponentData(
      // image: source.assetImagePath,
      label: zone.name,
      comPorts: <ComponentPort>[],
      inputPorts: <ComponentPort>[
        ComponentPort.fromPortData(zone.inputPort),
      ],
      outputPorts: <ComponentPort>[
        // ComponentPort(data: 0, label: "0"),
      ],
      circuit: zone,
      speakers: speakers,
    );
  }

  @override
  String get id => circuit.id;
  @override
  LocationModel? get location => null;
  @override
  Offset get portOffset => Offset(0, size.height / 2 - portRadius);
  @override
  Size get size => const Size(100, 100);

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
      inputPorts:
          speaker.inputPortsData
              .map(
                (PortData e) => ComponentPort.fromPortData(
                  e,
                  // data: e.id,
                  // label: e.name,
                  // type: e.type,
                  // position: e.position,
                  // index: e.portNumber,
                  // compatibleTypes: e.compatibleTypes,
                ),
              )
              .toList(),
      outputPorts:
          speaker.outputPortsData
              .map(
                (PortData e) => ComponentPort.fromPortData(
                  e,
                  // data: e.id,
                  // label: e.name,
                  // type: e.type,
                  // position: e.position,
                  // index: e.portNumber,
                  // compatibleTypes: e.compatibleTypes,
                ),
              )
              .toList(),
      speaker: speaker,
    );
  }

  @override
  String get id => speaker.id;
  @override
  LocationModel? get location => speaker.locationEntity;
  @override
  Size get size => const Size(100, 100);
  @override
  Offset get portOffset => Offset(0, size.height / 2 - portRadius);
  @override
  double get portRadius => WiringViewConstants.portRadius / 2;

  @override
  String get type => 'speaker';
}
