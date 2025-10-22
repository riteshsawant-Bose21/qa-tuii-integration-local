import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/controller/state/wiring_state.dart';
import 'package:fusion_launcher/features/wiring_design/model/canvas_element.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_port.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

abstract class BasePainter {
  final CircuitController controller;
  final ColorScheme colorScheme;

  BasePainter({required this.controller, required this.colorScheme});
  void paint(Canvas canvas, Size size);
  CanvasElement? isHit(Offset position);

  /// ------------------------------------------------------------------------
  ///
  ///
  ///  HELPER FUNCTIONS
  ///
  ///
  /// ------------------------------------------------------------------------

  bool isSelected(CanvasElement component) {
    return switch (controller.state) {
      ElementSelectionState(element: final CanvasElement element) =>
        element == component,
      ElementMovingState(element: final CanvasElement element) =>
        element == component,
      ConnectionProgressWiringState(
        port: final CircuitPort port,
      ) =>
        port == component,
      _ => false,
    };
  }

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
    Alignment positionAlignment = Alignment.center,
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
        position.dx - tp.width / 2 - tp.width * 0.5 * positionAlignment.x,
        position.dy - tp.height / 2 - tp.height * 0.5 * positionAlignment.y,
      ),
    );
    return true;
  }
}
