import 'dart:ui';


import 'canvas_element.dart';
import 'circuit_port.dart';

class CircuitComponent extends CanvasElement {
  final String id;
  @override
  Offset position; // Top-left corner
  @override
  Size size;
  final List<CircuitPort> ports;
  CircuitComponent({
    required this.id,
    required this.position,
    required this.size,
    required this.ports,
  });
}
