import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/wiring_stats_methods.dart';
import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';
import 'package:fusion_launcher/features/wiring_design/model/model.dart';
import 'package:fusion_launcher/features/wiring_design/util/canvas_util.dart';
import 'package:fusion_launcher/features/wiring_design/util/color_util.dart';
import 'package:fusion_launcher/features/wiring_design/view/painters/base_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

part './component/base_component_painter.dart';
part './component/circuit_component_painter.dart';
part './component/device_schematic_component_painter.dart';
part './component/source_component_painter.dart';
part './component/speaker_component_painter.dart';
part './component/subzone_component_painter.dart';
part './component/zone_component_painter.dart';

class ComponentPainter extends BasePainter {
  final CircuitComponent component;
  ComponentPainter({
    required this.component,
    required super.controller,
    required super.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ComponentDataPainter comPainter = switch (component.data) {
      DeviceSchematicComponentData() => DeviceSchematicComponentPainter(
        component,
        this,
      ),
      SourceComponentData() => SourceComponentPainter(
        component: component,
        painter: this,
      ),
      SpeakerComponentData() => SpeakerComponentPainter(
        component: component,
        painter: this,
      ),
      ZoneComponentData() => ZoneComponentPainter(
        component: component,
        painter: this,
      ),
      SubZoneComponentData() => SubZoneComponentPainter(
        component: component,
        painter: this,
      ),
      CircuitComponentData() => CircuitComponentPainter(
        component: component,
        painter: this,
      ),
      _ => BaseComponentPainter(component: component, painter: this),
    };

    comPainter.paint(canvas, size);
    final LocationModel? location2 = component.data.location;
    if (location2 == null) return;
    final Zone? zone = getZoneData(component.data.id);
    final String? locationName = getLocationName(location2.listeningAreaId);
    final String? eqLocationName = getEquipmentLocationName(component.data.id);
    final Offset offset = Offset(
      component.position.dx,
      component.position.dy + (component.size).height + 10,
    );
    if (zone != null) {
      canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy, 10, 30),
        Paint()..color = zone.color,
      );
    }

    drawText(
      canvas: canvas,
      text: zone?.name ?? locationName ?? eqLocationName ?? "Eq. Location",
      position: offset + const Offset(15, 5),
      positionAlignment: Alignment.topLeft,
    );
  }

  /// Get location name from listeningAreaId
  String? getLocationName(String? listeningAreaId) {
    // if (listeningAreaId == null)
    return null;

    // final ListeningArea area = serviceLocator<ProjectViewModel>().getListeningArea(areaId: listeningAreaId);
    //
    // return area.name;
  }

  /// Get Eqipm location id
  String? getEquipmentLocationName(String? listeningAreaId) {
    if (listeningAreaId == null) return null;

    final EquipLocation? area = serviceLocator<ProjectViewModel>().getEquipLocationForHardware(hardwareId: listeningAreaId);
    print("Equipment Location Area: ${area?.name}");
    return area?.name;
  }

  /// Get zone data from hardwareId
  Zone? getZoneData(String hardwareId) {
    return serviceLocator<ProjectViewModel>().getZoneForHardware(
      hardwareId: hardwareId,
    );
  }

  @override
  CanvasElement? isHit(Offset position) {
    return component.isHit(position);
    // for (final CircuitPort port in component.ports) {
    //   final Rect portRect = Rect.fromCircle(
    //     center: component.position + port.relativePosition,
    //     radius: WiringViewConstants.portRadius,
    //   );
    //   if (portRect.contains(position)) {
    //     return port;
    //   }
    // }
    // final Rect rect = component.position & component.size;
    // if (rect.contains(position)) {

    //   return component;
    // }
  }

  bool hasConnection(CircuitPort port) {
    return controller.hasConnection(port);
  }
}

abstract class ComponentDataPainter {
  void paint(Canvas canvas, Size size);
}
