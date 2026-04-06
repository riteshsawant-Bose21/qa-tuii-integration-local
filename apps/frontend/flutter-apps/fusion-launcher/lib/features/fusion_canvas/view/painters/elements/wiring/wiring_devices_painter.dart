import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/connection_manager.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'port_painter.dart';

class WiringDevicesPainter extends FusionCanvasElementPainter with PortPainter {
  final ConnectionManager  connectionManager;
  final HardwareComponent device;
  WiringDevicesPainter({required this.device, required this.connectionManager}) : super(item: FusionCanvasItem(id: device.id)) {
    double maxHeight = 0;
    double inputPosY = portRadius;
    for (int i = 0; i < device.inputPortsData.length; i++) {
      final WiringPortData wiringPortData = WiringPortData(position: Offset(0, inputPosY), port: device.inputPortsData[i], deviceId: device.id);
      _inputPorts.add(
        wiringPortData,
      );
      inputPosY += portRadius * 2 + 20.0;
      maxHeight = math.max(maxHeight, wiringPortData.position.dy + inputPortPadding.dy);
    }
    double outputPosY = portRadius;
    for (int i = 0; i < device.outputPortsData.length; i++) {
      final WiringPortData wiringPortData = WiringPortData(
        position: Offset(0, outputPosY),
        port: device.outputPortsData[i],
        deviceId: device.id,
      );
      _outputPorts.add(
        wiringPortData,
      );
      outputPosY += portRadius * 2 + 20.0;
      maxHeight = math.max(maxHeight, wiringPortData.position.dy + outputPortPadding.dy);
    }
    size = Size(size.width, maxHeight + portRadius * 2 + inputPortPadding.dy);
  }
  final List<WiringPortData> _inputPorts = <WiringPortData>[];
  final List<WiringPortData> _outputPorts = <WiringPortData>[];

  Size size = Size.zero;
  @override
  Offset getOffset() {
    return device.wiringPos ?? Offset.zero;
  }

  @override
  Size getSize() {
    return Size(700, size.height + headerHeight);
  }

  Offset get inputPortPadding => const Offset(40, 40);
  Offset get outputPortPadding => const Offset(-40, 40);

  double get headerHeight => 80;

  @override
  List<WiringPortData> getPorts(Rect rect, FusionCanvasPainter painter) {
    return <WiringPortData>[
      ..._inputPorts.map(
        (WiringPortData port) => port.copyWith(position: port.position + rect.topLeft + Offset(portRadius, 0) + inputPortPadding + Offset(0, headerHeight)),
      ),
      ..._outputPorts.map(
        (WiringPortData port) => port.copyWith(position: port.position + rect.topRight - Offset(portRadius, 0) + outputPortPadding + Offset(0, headerHeight)),
      ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Rect rect = getTransformedRect(painter);

    final Paint paint =
        Paint()
          ..color = painter.context.colorScheme.elevation1
          ..style = PaintingStyle.fill;
    final double radius = 35;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);

    final Paint portContainer =
        Paint()
          ..color = painter.context.colorScheme.elevation2
          ..style = PaintingStyle.fill;

    /// Input Port Container
    final RRect inputRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        rect.left + inputPortPadding.dx / 2,
        rect.top + inputPortPadding.dy / 2,
        rect.left + inputPortPadding.dx * 1.5 + portRadius * 2,
        rect.bottom - outputPortPadding.dy / 2,
      ),
      Radius.circular(radius * 0.5),
    );
    canvas.drawRRect(
      inputRect,
      portContainer,
    );
    drawText(
      canvas: canvas,
      text: "IN",
      position: Offset(inputRect.center.dx, inputRect.top + headerHeight * 0.5),
      positionAlignment: Alignment.center,
      style: painter.context.textTheme.l1Regular.copyWith(
        fontSize: headerHeight * 0.3,
        color: painter.context.colorScheme.onPrimary,
      ),
    );

    ///
    /// Output Port Container
    ///
    final RRect outPutPort = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        rect.right + outputPortPadding.dx * 1.5 - portRadius * 2,
        rect.top + outputPortPadding.dy / 2,
        rect.right + outputPortPadding.dx / 2,
        rect.bottom - outputPortPadding.dy / 2,
      ),
      Radius.circular(radius * 0.5),
    );

    canvas.drawRRect(
      outPutPort,
      portContainer,
    );
    drawText(
      canvas: canvas,
      text: "OUT",
      position: Offset(outPutPort.center.dx, outPutPort.top + headerHeight * 0.5),
      positionAlignment: Alignment.center,
      style: painter.context.textTheme.l1Regular.copyWith(
        fontSize: headerHeight * 0.3,
        color: painter.context.colorScheme.onPrimary,
      ),
      maxWidth: outPutPort.width,
    );

    final double imagePadding = 20.0;
    final Rect imageRect = Rect.fromLTWH(
      inputRect.right + imagePadding,
      inputRect.top,
      outPutPort.left - inputRect.right - 2 * imagePadding,
      150,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(imageRect, Radius.circular(radius * 0.8)), Paint()..color = Colors.grey);

    drawImage(canvas: canvas, imagePath: device.assetImagePath, rect: imageRect.deflate(imagePadding), painter: painter);
    final Rect textRect = Rect.fromLTRB(
      imageRect.left,
      imageRect.bottom + imagePadding,
      imageRect.right,
      math.max(outPutPort.bottom, inputRect.bottom),
    );
    drawText(
      canvas: canvas,
      text: device.hardwareName,
      position: textRect.topLeft,
      positionAlignment: Alignment.topLeft,
      style: painter.context.textTheme.b2Bold.copyWith(
        fontSize: imageRect.height * 0.2,
      ),
    );

    paintPorts(canvas, size, painter);
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! WiringDevicesPainter) return true;
    return oldDelegate.device != device;
  }
}
