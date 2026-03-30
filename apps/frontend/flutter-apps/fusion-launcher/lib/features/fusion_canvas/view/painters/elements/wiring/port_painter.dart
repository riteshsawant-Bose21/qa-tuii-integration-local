// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';

import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas_painter.dart';

mixin PortPainter on FusionCanvasElementPainter {
  List<WiringPortData> getPorts(Rect rect, FusionCanvasPainter painter);

  void paintPorts(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Rect rect = getTransformedRect(painter);
    final List<WiringPortData> ports = getPorts(Offset.zero & rect.size, painter);
    for (final WiringPortData portData in ports) {
      final Offset transformedPosition = portData.position + rect.topLeft;
      canvas.drawCircle(
        transformedPosition,
        portRadius,
        Paint()..color = painter.context.colorScheme.primary,
      );
    }
  }

  double get portRadius => 20;

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    final FusionCanvasElement? component = super.isHit(position, painter);
    if (component != null) {
      final List<WiringPortData> ports = getPorts(Offset.zero & getTransformedRect(painter).size, painter);
      for (final WiringPortData portData in ports) {
        final Rect portRect = Rect.fromCircle(center: portData.position + getTransformedRect(painter).topLeft, radius: portRadius);
        if (portRect.contains(position)) {
          return portData;
        }
      }
    }
    return component;
  }
}

class WiringPortData extends FusionCanvasItem {
  final PortData port;
  final Offset position;

  WiringPortData({
    required this.position,
    required this.port,
  }) : super(id: port.id);

  WiringPortData copyWith({
    PortData? port,
    Offset? position,
  }) {
    return WiringPortData(
      port: port ?? this.port,
      position: position ?? this.position,
    );
  }
}
