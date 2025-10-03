import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/model/canvas_element.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

abstract class BasePainter {
  final CircuitController controller;
  final ColorScheme colorScheme;
  ui.Image? getImage(String path) {
    return controller.imagesCache[path];
  }

  bool drawImage({
    required Canvas canvas,
    required String path,
    required Rect rect,
  }) {
    final ui.Image? image = getImage(path);
    if (image != null) {
      final Rect src = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );

      canvas.drawImageRect(image, src, rect, Paint());
      return true;
    }
    return false;
  }

  bool drawText({
    required Canvas canvas,
    required String text,
    TextStyle? style,
    required Offset position,
    double maxWidth = double.infinity,
  }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style:
            style ??
            TextStyle(
              color: colorScheme.componentFG,
            ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    // Center Align lable
    tp.paint(
      canvas,
      Offset(
        position.dx - tp.width / 2,
        position.dy - tp.height / 2,
      ),
    );
    return true;
  }

  BasePainter({required this.controller, required this.colorScheme});
  void paint(Canvas canvas, Size size);
  // bool shouldRepaint(covariant BasePainter oldDelegate);

  CanvasElement? isHit(Offset position);
}
