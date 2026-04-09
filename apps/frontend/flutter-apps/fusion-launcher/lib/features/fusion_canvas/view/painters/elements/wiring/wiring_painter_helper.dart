import 'package:flutter/widgets.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../configuration/presentation/viewmodel/project_view_model.dart';

mixin WiringPainterHelper on FusionCanvasElementPainter {
  void drawDeviceInfo({
    required Canvas canvas,
    required Rect textRect,

    required String name,
    required String hardwareName,
    required LocationModel location,
    required FusionCanvasPainter painter,
    double textSize = 40.0,
  }) {
    final double scaling = textSize;
    drawText(
      canvas: canvas,
      text: name,
      position: textRect.topLeft,
      positionAlignment: Alignment.topLeft,
      style: painter.context.textTheme.b2Bold.copyWith(
        fontSize: scaling,
      ),
    );
    drawText(
      canvas: canvas,
      text: hardwareName,
      position: textRect.topLeft + Offset(0, scaling + 20),
      positionAlignment: Alignment.topLeft,
      style: painter.context.textTheme.l2Regular.copyWith(
        fontSize: scaling * 0.5,
        color: painter.context.colorScheme.textSecondary,
      ),
    );
    final Zone? zone = getZoneData(id ?? "");
    final String? locationName = getLocationName(location.listeningAreaId);
    final String? eqLocationName = getEquipmentLocationName(id);
    final Offset locationOffset = textRect.topLeft + Offset(0, scaling + 20) + Offset(0, (scaling * 0.5) + 15);
    if (zone != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(locationOffset.dx, locationOffset.dy, 20, 20),
          const Radius.circular(4),
        ),
        Paint()..color = zone.color,
      );
      drawText(
        canvas: canvas,
        text: zone.name,
        position: locationOffset + const Offset(25, 2),
        positionAlignment: Alignment.topLeft,
        style: painter.context.textTheme.l2Regular.copyWith(
          fontSize: scaling * 0.4,
          color: painter.context.colorScheme.textSecondary,
        ),
      );
    } else {
      drawImage(
        canvas: canvas,
        imagePath: 'assets/icons/wiring_ports/equipment_location_icon.png',
        rect: Rect.fromLTWH(locationOffset.dx, locationOffset.dy, 20, 20),
        painter: painter,
        color: painter.context.colorScheme.primaryWhite,
      );
      drawText(
        canvas: canvas,
        text: locationName ?? eqLocationName ?? "Eq. Location",
        position: locationOffset + const Offset(25, 2),

        positionAlignment: Alignment.topLeft,
        style: painter.context.textTheme.l2Regular.copyWith(
          fontSize: scaling * 0.4,
          color: painter.context.colorScheme.textSecondary,
        ),
      );
    }
  }

  /// Get location name from listeningAreaId
  String? getLocationName(String? listeningAreaId) {
    // if (listeningAreaId == null)
    return null;

    // final ListeningArea area = serviceLocator<ProjectViewModel>().getListeningArea(areaId: listeningAreaId);
    //
    // return area.name;
  }

  /// Get Equipment location id
  String? getEquipmentLocationName(String? listeningAreaId) {
    if (listeningAreaId == null) return null;

    final EquipLocation? area = serviceLocator<ProjectViewModel>().getEquipLocationForHardware(hardwareId: listeningAreaId);
    return area?.name;
  }

  /// Get zone data from hardwareId
  Zone? getZoneData(String hardwareId) {
    return serviceLocator<ProjectViewModel>().getZoneForHardware(
      hardwareId: hardwareId,
    );
  }
}
