import 'dart:ui';

import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/model/canvas_element.dart';

abstract class BasePainter {
  final CircuitController controller;

  BasePainter({required this.controller});
  void paint(Canvas canvas, Size size);
  // bool shouldRepaint(covariant BasePainter oldDelegate);

  CanvasElement? isHit(Offset position);
}
