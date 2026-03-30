import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'port_painter.dart';

class WiringSourcePainter extends FusionCanvasElementPainter with PortPainter {
  final Source source;
  WiringSourcePainter({required this.source}) : super(item: FusionCanvasItem(id: source.id));

  @override
  Offset getOffset() {
    return source.wiringPos ?? Offset.zero;
  }

  @override
  Size getSize() {
    return const Size(400, 150);
  }

  @override
  List<WiringPortData> getPorts(Rect rect, FusionCanvasPainter painter) {
    return source.outputPortsData.map((PortData port) => WiringPortData(position: rect.centerRight - Offset(portRadius + 20, 0), port: port)).toList();
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

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Rect rect = getTransformedRect(painter);

    final Paint paint =
        Paint()
          ..color = painter.context.colorScheme.elevation1
          ..style = PaintingStyle.fill;
    final double radius = rect.height / 5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
    final double imagePadding = rect.height * 0.1;
    final Rect imageRect = Rect.fromLTWH(rect.left + imagePadding, rect.top + imagePadding, rect.height - 2 * imagePadding, rect.height - 2 * imagePadding);
    canvas.drawRRect(RRect.fromRectAndRadius(imageRect, Radius.circular(radius * 0.8)), Paint()..color = Colors.grey);
    drawImage(canvas: canvas, imagePath: source.assetImagePath, rect: imageRect.deflate(imagePadding), painter: painter);
    final Rect textRect = Rect.fromLTWH(
      imageRect.right + imagePadding,
      rect.top + imagePadding,
      rect.width - imageRect.width - 3 * imagePadding,
      rect.height - 2 * imagePadding,
    );
    drawText(
      canvas: canvas,
      text: source.hardwareName,
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
    if (oldDelegate is! WiringSourcePainter) return true;
    return oldDelegate.source != source;
  }
}
