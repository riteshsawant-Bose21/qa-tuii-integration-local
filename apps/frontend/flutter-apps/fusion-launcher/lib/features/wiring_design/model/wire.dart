import 'dart:ui';


import 'canvas_element.dart';
import 'circuit_port.dart';

class Wire extends CanvasElement {
  final String id;
  CircuitPort from;
  CircuitPort to;
  List<Offset> joints; // includes start and end

  Wire({
    required this.id,
    required this.from,
    required this.to,
    required this.joints,
  });

  @override
  Offset get position => Offset(
    from.absolutePositionWithOffset.dx,
    to.absolutePositionWithOffset.dy,
  );

  @override
  Size get size => Size(
    (to.absolutePositionWithOffset.dx - from.absolutePositionWithOffset.dx)
        .abs(),
    (to.absolutePositionWithOffset.dy - from.absolutePositionWithOffset.dy)
        .abs(),
  );
}
