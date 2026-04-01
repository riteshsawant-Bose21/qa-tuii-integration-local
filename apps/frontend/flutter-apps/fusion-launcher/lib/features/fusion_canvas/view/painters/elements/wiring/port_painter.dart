// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas_painter.dart';

mixin PortPainter on FusionCanvasElementPainter {
  List<WiringPortData>? _ports;
  List<WiringPortData> getPorts(Rect rect, FusionCanvasPainter painter);

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

  void paintPorts(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Rect rect = getTransformedRect(painter);
    final List<WiringPortData> ports = _ports ?? getPorts(Offset.zero & rect.size, painter);
    _ports = ports;
    for (final WiringPortData portData in ports) {
      final Offset transformedPosition = portData.position + rect.topLeft;
      canvas.drawCircle(
        transformedPosition,
        portRadius,
        Paint()..color = painter.context.colorScheme.primary,
      );
    }
  }

  Offset? getPortPosition(String portId, FusionCanvasPainter painter) {
    final WiringPortData? portData = _ports?.firstWhereOrNull((WiringPortData data) => data.id == portId);
    if (portData != null) {
      final Rect rect = getTransformedRect(painter);
      return portData.position + rect.topLeft;
    }
    return null;
  }

  

  double get portRadius => 20;

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    final FusionCanvasElement? component = super.isHit(position, painter);
    if (component != null) {
      final List<WiringPortData> ports = _ports ?? getPorts(Offset.zero & getTransformedRect(painter).size, painter);
      _ports = ports;
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
  final String deviceId;
  WiringPortData({
    required this.position,
    required this.port,
    required this.deviceId,
  }) : super(id: port.id);

  WiringPortData copyWith({
    PortData? port,
    Offset? position,
    String? deviceId,
  }) {
    return WiringPortData(
      port: port ?? this.port,
      position: position ?? this.position,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
