// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/connection_color_util.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/connection_manager.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas_painter.dart';

mixin PortPainter on FusionCanvasElementPainter {
  ConnectionManager get connectionManager;
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
      final WiringConnectionModel? connection = connectionManager.getConnectionForPort(portData.id);
      final Color portColor =
          connection != null ? ConnectionColorUtil.getColorForConnectionType(connection.type) : ConnectionColorUtil.getColorForPortType(portData.port.type);
      final bool isConnected = connection != null;
      if (portData.image != null) {
        _paintPortWithImage(
          canvas: canvas,
          position: transformedPosition,
          imagePath: portData.image ?? 'assets/icons/wiring_ports/${portData.port.type}_port.png',
          painter: painter,
          portData: portData,
          portColor: portColor,
          isConnected: isConnected,
        );
      } else {
        _drawDefaultPort(
          canvas: canvas,
          position: transformedPosition,
          color: portColor,
          painter: painter,
          portData: portData,
          isConnected: isConnected,
        );
      }
    }
  }

  void _drawDefaultPort({
    required Canvas canvas,
    required Offset position,
    required Color color,
    required FusionCanvasPainter painter,
    required WiringPortData portData,
    required bool isConnected,
  }) {
    canvas.drawCircle(
      position,
      portRadius,
      Paint()
        ..color = isConnected ? color : painter.context.colorScheme.elevation4
        ..style = isConnected ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    drawText(
      canvas: canvas,
      text: portData.port.name,
      position: position,
      positionAlignment: Alignment.center,
      style: painter.context.textTheme.b3Regular.copyWith(
        color: isConnected ? Colors.black : null,
        // fontSize: ,
      ),
    );
  }

  void _paintPortWithImage({
    required Canvas canvas,
    required Offset position,
    required String imagePath,
    required FusionCanvasPainter painter,
    required WiringPortData portData,
    required Color portColor,
    required bool isConnected,
  }) {
    final Rect portRect = Rect.fromCircle(center: position, radius: portRadius);
    drawImage(canvas: canvas, imagePath: imagePath, rect: portRect.deflate(portRadius * 0.1), painter: painter, paint: Paint()..color = Colors.white);

    canvas.drawCircle(
      position,
      portRadius,
      Paint()
        ..color = isConnected ? portColor : painter.context.colorScheme.elevation4
        ..style = isConnected ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    if (portData.image != null) {
      drawImage(
        canvas: canvas,
        imagePath: portData.image!,
        rect: Rect.fromCircle(center: position, radius: portRadius).deflate(portRadius * 0.25),
        painter: painter,
        paint:
            Paint()
              ..colorFilter = ColorFilter.mode(
                !isConnected ? portColor : Colors.black, // The solid color you want
                BlendMode.srcIn, // Replaces image pixels with the color
              )
              ..style = PaintingStyle.fill,
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
  final String? image;
  WiringPortData({
    required this.position,
    required this.port,
    required this.deviceId,
    this.image,
  }) : super(id: port.id);

  WiringPortData copyWith({
    PortData? port,
    Offset? position,
    String? deviceId,
    String? image,
  }) {
    return WiringPortData(
      port: port ?? this.port,
      position: position ?? this.position,
      deviceId: deviceId ?? this.deviceId,
      image: image ?? this.image,
    );
  }
}
