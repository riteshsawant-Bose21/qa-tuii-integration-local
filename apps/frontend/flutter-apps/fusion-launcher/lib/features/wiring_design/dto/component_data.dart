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
      comPorts: <ComponentPort>[
        ComponentPort(
          image: 'assets/icons/wiring_ports/stereo.png',
          data: 'stereo_1',
          type: 'stereo',
          label: "Stereo",
          compatibleTypes: <String>['stereo'],
          position: PortPosition.bottomLeft,
          index: 0,
        ),
        ComponentPort(
          image: 'assets/icons/wiring_ports/hdmi.png',
          data: 'hdmi_1',
          type: 'hdmi',
          label: "HDMI",
          compatibleTypes: <String>['hdmi'],
          position: PortPosition.bottomLeft,
          index: 1,
        ),
        ComponentPort(
          image: 'assets/icons/wiring_ports/usb.png',
          data: 'usb_1',
          type: 'usb',
          label: "USB",
          compatibleTypes: <String>['usb'],
          position: PortPosition.bottomLeft,
          index: 2,
        ),

        // ComponentPort(
        //   image: 'assets/icons/wiring_ports/ethernet.png',
        //   data: 'ethernet_1',
        //   type: 'ethernet',
        //   label: "Ethernet 1",
        //   compatibleTypes: <String>['ethernet'],
        //   position: PortPosition.footerLeft,
        // ),
        // ComponentPort(
        //   image: 'assets/icons/wiring_ports/ethernet.png',
        //   data: 'ethernet_2',
        //   type: 'ethernet',
        //   label: "Ethernet 2",
        //   compatibleTypes: <String>['ethernet'],
        //   position: PortPosition.footerLeft,
        // ),
        ComponentPort(
          image: 'assets/icons/wiring_ports/wifi.png',
          data: 'wifi',
          type: 'wifi',
          label: "Wifi",
          compatibleTypes: <String>['wifi'],
          position: PortPosition.footerCenter,
        ),
        // ComponentPort(
        //   image: 'assets/icons/wiring_ports/wifi.png',
        //   data: 'wifi_!',
        //   type: 'wifi',
        //   label: "Wifi",
        //   compatibleTypes: <String>['wifi'],
        //   position: PortPosition.footerCenter,
        // ),
        // ComponentPort(
        //   image: 'assets/icons/wiring_ports/bluetooth.png',
        //   data: 'bluetooth',
        //   type: 'bluetooth',
        //   label: "Bluetooth",
        //   compatibleTypes: <String>['bluetooth'],
        //   position: PortPosition.footerRight,
        // ),
        // ComponentPort(
        //   image: 'assets/icons/wiring_ports/bluetooth.png',
        //   data: 'bluetooth_1',
        //   type: 'bluetooth',
        //   label: "Bluetooth",
        //   compatibleTypes: <String>['bluetooth'],
        //   position: PortPosition.footerRight,
        // ),
      ],
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
        max(0, extraHeight - 1) * WiringViewConstants.portSpacing,
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

enum PortPosition {
  bottomLeft,
  bottomRight,
  footerLeft,
  footerRight,
  footerCenter,
}
