// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../wiring_design/algorithm/connection_manager.dart' show ConnectionManager;
import '../../../../../wiring_design/algorithm/zone_manager.dart';
import 'port_painter.dart';

class WiringZonePainter extends FusionCanvasElementPainter with PortPainter {
  @override
  final ConnectionManager connectionManager;
  final Zone zone;
  final WiringZoneManager zoneManager;
  WiringZonePainter({required this.zone, required this.zoneManager, required this.connectionManager}) : super(item: FusionCanvasItem(id: zone.id)) {
    updatePainters();
  }

  final List<_SubZonePainter> subZonePainters = <_SubZonePainter>[];
  final List<_CircuitPainter> circuitPainters = <_CircuitPainter>[];
  @override
  Offset getOffset() {
    return zone.wiringPos ?? Offset.zero;
  }

  @override
  Rect getTransformedRect(FusionCanvasPainter painter) {
    final Offset offset = getOffset();
    final Size size = getSize();
    return Rect.fromCenter(
      center: transformOffsetForLayer(offset, painter, id),
      width: size.width,
      height: size.height,
    );
  }

  double get headerHeight => 100;
  double get outerSpacing => 30;
  void updatePainters() {
    Size effectiveSize = Size(700, headerHeight);

    final Offset position = getRect().topLeft;
    final List<SubZone> subZones = zoneManager.getSubZonesForZone(zone.id);
    subZonePainters.clear();

    effectiveSize += Offset(0, outerSpacing);

    for (final SubZone subZone in subZones) {
      final Offset position2 = position + Offset(outerSpacing, effectiveSize.height);
      final _SubZonePainter subZonePainter = _SubZonePainter(
        subZone: subZone,
        connectionManager: connectionManager,
        zoneManager: zoneManager,
        baseId: zone.id,
        zone: zone,
        position: position2,
      );
      final Size subZoneSize = subZonePainter.getSize();
      subZonePainters.add(subZonePainter);
      effectiveSize = Size(
        max(effectiveSize.width, subZoneSize.width + outerSpacing * 2),
        effectiveSize.height + subZoneSize.height + outerSpacing,
      );
    }
    if (subZones.isNotEmpty) {
      effectiveSize += Offset(0, outerSpacing);
    }

    final List<CircuitModel> circuits = zoneManager.getCircuitsInZone(zone.id);
    circuitPainters.clear();
    for (final CircuitModel circuit in circuits) {
      final Offset position2 = position + Offset(outerSpacing, effectiveSize.height);
      final _CircuitPainter circuitPainter = _CircuitPainter(
        circuit: circuit,
        position: position2,
        baseId: zone.id,
        zoneManager: zoneManager,
        connectionManager: connectionManager,
      );
      final Size circuitSize = circuitPainter.getSize();
      circuitPainters.add(circuitPainter);
      effectiveSize = Size(
        max(effectiveSize.width, circuitSize.width + outerSpacing * 2),
        effectiveSize.height + circuitSize.height + outerSpacing,
      );
    }
    size = effectiveSize;
  }

  Size size = Size.zero;
  @override
  Size getSize() {
    return size;
  }

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    updatePainters();
    final Rect rect = getTransformedRect(painter);
    final Paint paint =
        Paint()
          ..color = painter.context.colorScheme.elevation1
          ..style = PaintingStyle.fill;
    final double radius = 25;

    ///
    /// BG Container
    ///
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);

    ///
    /// Headder
    ///

    final Rect contentRect = rect.deflate(outerSpacing);

    /// Headder BG
    final Rect headerRect = contentRect.topLeft & Size(contentRect.width, headerHeight);
    // canvas.drawRect(headerRect, Paint()..color = Colors.red);

    final RRect rrect = RRect.fromRectAndRadius(
      headerRect.topLeft & Size.square(headerHeight * 0.5),
      const Radius.circular(10),
    );

    final Color zoneColor = zone.color;
    canvas.drawRRect(rrect, Paint()..color = zoneColor);
    drawText(
      canvas: canvas,
      text: zone.name,
      position: headerRect.topLeft + const Offset(20, 0) + Offset(rrect.width, 0),
      style: painter.context.textTheme.b2Bold.copyWith(
        fontSize: headerHeight * 0.3,
      ),
      positionAlignment: Alignment.topLeft,
    );

    ///
    /// Content
    ///

    for (final _SubZonePainter subZonePainter in subZonePainters) {
      final Size subZoneSize = subZonePainter.getSize();
      subZonePainter.paint(canvas, subZoneSize, painter);
    }
    for (final _CircuitPainter circuitPainter in circuitPainters) {
      final Size circuitSize = circuitPainter.getSize();
      circuitPainter.paint(canvas, circuitSize, painter);
    }
    paintPorts(canvas, size, painter);
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }

  @override
  List<WiringPortData> getPorts(Rect rect, FusionCanvasPainter painter) {
    final Rect rect = getTransformedRect(painter);
    return <WiringPortData>[
      ...circuitPainters.expand((_CircuitPainter portData) => portData.getPorts(rect.topLeft, painter)),
      ...subZonePainters.expand((_SubZonePainter portData) => portData.getPorts(rect.topLeft, painter)),
    ];
  }
}

class _CircuitPainter extends FusionCanvasElementPainter {
  CircuitModel circuit;
  final Offset position;
  final String baseId;
  final WiringZoneManager zoneManager;

  final ConnectionManager connectionManager;
  _CircuitPainter({
    required this.circuit,
    required this.position,
    required this.baseId,
    required this.zoneManager,
    required this.connectionManager,
  }) : super(item: FusionCanvasItem(id: circuit.id));

  @override
  Size getSize() {
    return const Size(700, 200);
  }

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Offset pos = transformOffsetForLayer(position, painter, baseId);
    final int portRadius = 20;
    final Rect rect = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
    final Paint paint =
        Paint()
          ..color = painter.context.colorScheme.elevation2
          ..style = PaintingStyle.fill;
    final double radius = rect.height / 5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
    final double contentPadding = rect.height * 0.1;
    final Rect contentRect = Rect.fromLTRB(
      rect.left + contentPadding + portSpace * 2 + portRadius,
      rect.top + contentPadding,
      rect.right - contentPadding,
      rect.bottom - contentPadding,
    );
    final Rect textRect = Rect.fromLTWH(
      contentRect.left,
      contentRect.top,
      contentRect.width / 3,
      contentRect.height,
    );
    final Rect speakerRect = Rect.fromLTRB(
      textRect.right + 20,
      contentRect.top,
      contentRect.right,
      contentRect.bottom,
    );

    final List<HardwareComponent> hardwares = zoneManager.getHardwareComponentsInCircuit(circuit.id);
    final HardwareComponent? hardware = hardwares.firstOrNull;
    // print("Drawing circuit ${circuit.name}, hardware=${hardware?.name}.  maxWidth=${textRect.width}");
    drawText(
      canvas: canvas,
      text: circuit.name,
      position: textRect.topLeft,
      positionAlignment: Alignment.topLeft,
      style: painter.context.textTheme.b2Bold.copyWith(fontSize: textRect.height * 0.2),
      maxWidth: textRect.width,
    );
    drawText(
      canvas: canvas,
      text: circuit.impedance ?? "",
      position: textRect.topLeft + Offset(0, textRect.height * 0.3),
      positionAlignment: Alignment.topLeft,
      style: painter.context.textTheme.b2Bold.copyWith(fontSize: textRect.height * 0.2),
      maxWidth: textRect.width,
    );

    canvas.drawRRect(RRect.fromRectAndRadius(speakerRect, Radius.circular(radius)), Paint()..color = painter.context.colorScheme.elevation1);
    final double imagePadding = speakerRect.height * 0.1;
    final Rect rect2 = Rect.fromLTWH(
      speakerRect.left + imagePadding,
      speakerRect.top + imagePadding,
      (speakerRect.width * 0.5) - imagePadding,
      speakerRect.height - 2 * imagePadding,
    );
    canvas.save();
    drawImage(
      canvas: canvas..clipRRect(RRect.fromRectAndRadius(rect2, Radius.circular(radius * 0.8))),
      imagePath: hardware?.assetImagePath ?? "",
      rect: rect2,
      painter: painter,
    );
    canvas.restore();

    drawText(
      canvas: canvas,
      text: "${hardware?.name ?? ""} x ${hardwares.length} ",
      position: rect2.centerRight + const Offset(20, 0),
      positionAlignment: Alignment.centerLeft,
      style: painter.context.textTheme.b2Bold.copyWith(fontSize: textRect.height * 0.15),
      maxWidth: (speakerRect.width * 0.5) - 40,
    );

    // paintPorts(canvas, size, painter);
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }

  double get portSpace => 20;
  final double portRadius = 20;

  List<WiringPortData> getPorts(Offset topLeft, FusionCanvasPainter painter) {
    // final Rect rect = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
    final Offset pos = transformOffsetForLayer(position, painter, baseId);
    final Size size = getSize();
    return <WiringPortData>[
      WiringPortData(
        image: 'assets/icons/wiring_ports/link.png',

        position:
            (pos - topLeft) +
            Offset(
              portRadius + portSpace,
              size.height / 2,
            ),
        port: circuit.inputPort,
        deviceId: circuit.id,
      ),
    ];
  }

  @override
  Set<FusionCanvasLayerInteraction> get possibleInteractions => <FusionCanvasLayerInteraction>{};

  @override
  Offset getOffset() {
    return position;
  }
}

class _SubZonePainter extends FusionBasePainter {
  SubZone subZone;
  final Offset position;
  final WiringZoneManager zoneManager;
  final String baseId;
  final Zone zone;

  final ConnectionManager connectionManager;
  _SubZonePainter({
    required this.subZone,
    required this.zoneManager,
    required this.position,
    required this.baseId,
    required this.zone,
    required this.connectionManager,
  }) {
    updatePainters();
  }

  final List<_CircuitPainter> circuitPainters = <_CircuitPainter>[];

  Size getSize() {
    final Size fold = circuitPainters
        .map((_CircuitPainter e) => e.getSize())
        .fold(
          const Size(0, 0),
          (Size previousValue, Size element) => Size(
            element.width,
            previousValue.height + element.height,
          ),
        );
    return (Size(fold.width + 40, fold.height + 50));
  }

  void updatePainters() {
    final List<CircuitModel> circuits = zoneManager.getCircuitsInSubZone(subZone.id);
    circuitPainters
      ..clear()
      ..addAll(
        circuits.map(
          (CircuitModel c) => _CircuitPainter(
            circuit: c,
            position: position + Offset(20, 20 + headerHeight),
            baseId: baseId,
            zoneManager: zoneManager,
            connectionManager: connectionManager,
          ),
        ),
      );
  }

  double get headerHeight => 75;
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    updatePainters();
    if (circuitPainters.isEmpty) {
      return;
    }
    final Offset pos = transformOffsetForLayer(position, painter, baseId);
    final Rect rect = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, 2), Paint()..color = painter.context.colorScheme.elevation2);

    final Rect headerRect = (rect.topLeft + Offset(0, headerHeight * 0.25)) & Size(rect.width, headerHeight);
    // canvas.drawRect(headerRect, Paint()..color = Colors.red);

    final RRect rrect = RRect.fromRectAndRadius(
      headerRect.topLeft & Size.square(headerHeight * 0.5),
      const Radius.circular(10),
    );

    final Color zoneColor = zone.color;
    canvas.drawRRect(rrect, Paint()..color = zoneColor);
    drawText(
      canvas: canvas,
      text: zone.name,
      position: headerRect.topLeft + const Offset(20, 0) + Offset(rrect.width, 0),
      style: painter.context.textTheme.b2Bold.copyWith(
        fontSize: headerHeight * 0.3,
      ),
      positionAlignment: Alignment.topLeft,
    );

    for (final _CircuitPainter circuit in circuitPainters) {
      final Size circuitSize = circuit.getSize();
      circuit.paint(canvas, circuitSize, painter);
    }
    // drawImage(canvas: canvas, imagePath: subZone.assetImagePath, rect: imageRect.deflate(imagePadding));
    // final Rect textRect = Rect.fromLTWH(
    //   imageRect.right + imagePadding,
    //   rect.top + imagePadding,
    //   rect.width - imageRect.width - 3 * imagePadding,
    //   rect.height - 2 * imagePadding,
    // );
    // drawText(
    //   canvas: canvas,
    //   text: subZone.name,
    //   position: textRect.topLeft,
    //   positionAlignment: Alignment.topLeft,
    //   style: TextStyle(
    //     fontSize: imageRect.height * 0.2,
    //     color: Colors.white,
    //   ),
    // );
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }

  List<WiringPortData> getPorts(Offset offset, FusionCanvasPainter painter) {
    return circuitPainters.expand((_CircuitPainter circuitPainter) => circuitPainter.getPorts(offset, painter)).toList();
  }
}
