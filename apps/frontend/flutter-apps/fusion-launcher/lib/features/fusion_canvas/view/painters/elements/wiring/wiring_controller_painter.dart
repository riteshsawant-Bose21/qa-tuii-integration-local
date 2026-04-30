import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'port_painter.dart';
import 'wiring_devices_painter.dart';

class WiringControllerPainter extends WiringDevicesPainter {
  WiringControllerPainter({required super.device, required super.connectionManager}) {
    leftPorts.addAll(
      device.inputPortsData.map(
        (PortData port) => WiringPortData(
          position: Offset(portRadius + 20, 0),
          port: port,
          deviceId: device.id,
          portAlignment: Alignment.centerLeft,
        ),
      ),
    );

    rightPorts.addAll(<WiringPortData>[
      ...device.outputPortsData.map(
        (PortData port) => WiringPortData(
          position: Offset(-portRadius - 20, 0),
          port: port,
          deviceId: device.id,
          image: 'assets/icons/wiring_ports/link.png',
          portAlignment: Alignment.centerRight,
        ),
      ),
      ...device.communicationPorts.map(
        (PortData port) => WiringPortData(
          position: Offset(-portRadius - 10, 0),
          port: port,
          deviceId: device.id,
          portAlignment: Alignment.centerRight,
        ),
      ),
    ]);
  }

  @override
  Offset getOffset() {
    return device.wiringPos ?? Offset.zero;
  }

  @override
  Size getSize() {
    return const Size(450, 150) +
        Offset(
          (leftPorts.isNotEmpty ? (portRadius * 2) : 0) + (rightPorts.isNotEmpty ? portRadius * 2 : 0),
          0,
        );
  }

  final List<WiringPortData> leftPorts = <WiringPortData>[];
  final List<WiringPortData> rightPorts = <WiringPortData>[];
  @override
  List<WiringPortData> getPorts(Rect rect, FusionCanvasPainter painter) {
    return <WiringPortData>[
      ...leftPorts.map((WiringPortData port) => port.copyWith(position: port.position + rect.centerLeft)),
      ...rightPorts.map((WiringPortData port) => port.copyWith(position: port.position + rect.centerRight)),
    ];
  }

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Rect rect = getTransformedRect(painter);

    final Paint paint =
        Paint()
          ..color = painter.context.colorScheme.elevation1
          ..style = PaintingStyle.fill;
    final double radius = rect.height / 5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
    final Rect contentRect = Rect.fromLTRB(
      rect.left + (leftPorts.isNotEmpty ? portRadius * 2 + 20 : 0),
      rect.top,
      rect.right - (rightPorts.isNotEmpty ? portRadius * 2 + 20 : 0),
      rect.bottom,
    );
    // canvas.drawRect(
    //   contentRect,
    //   Paint()
    //     ..color = Colors.red
    //     ..style = PaintingStyle.fill,
    // );
    final double imagePadding = contentRect.height * 0.1;

    final Rect imageRect = Rect.fromLTWH(
      contentRect.left + imagePadding,
      contentRect.top + imagePadding,
      contentRect.height - 2 * imagePadding,
      contentRect.height - 2 * imagePadding,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(imageRect, Radius.circular(radius * 0.8)), Paint()..color = Colors.grey);
    drawImage(canvas: canvas, imagePath: device.image, rect: imageRect.deflate(imagePadding), painter: painter);
    final Rect textRect = Rect.fromLTWH(
      imageRect.right + imagePadding,
      contentRect.top + imagePadding,
      contentRect.width - imageRect.width - 3 * imagePadding,
      contentRect.height - 2 * imagePadding,
    );

    drawDeviceInfo(
      canvas: canvas,
      textRect: textRect,
      name: device.name,
      textSize: 30,
      hardwareName: device.hardwareName,
      location: device.locationEntity,
      painter: painter,
    );
    paintPorts(canvas, size, painter);
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! WiringControllerPainter) return true;
    return oldDelegate.device != device;
  }
}
