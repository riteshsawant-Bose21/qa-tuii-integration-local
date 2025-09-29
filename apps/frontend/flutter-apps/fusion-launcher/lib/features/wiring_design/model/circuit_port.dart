import 'package:flutter/material.dart';

import 'canvas_element.dart';
import 'circuit_component.dart';

class CircuitPort extends CanvasElement {
  final String id;
  Offset relativePosition;
  Offset padding;
  CircuitComponent parent;

  CircuitPort({
    required this.id,
    required this.relativePosition,
    required this.padding,
    required this.parent,
  });

  Offset get absolutePosition => parent.position + relativePosition;
  Offset get absolutePositionWithOffset => absolutePosition + padding;

  @override
  Offset get position => absolutePosition;

  @override
  Size get size => const Size(5, 5);
}
