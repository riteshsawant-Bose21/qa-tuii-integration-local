import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';

import 'canvas_element.dart';
import 'circuit_component.dart';

class CircuitPort extends CanvasElement {
  final String id;
  Offset relativePosition;
  Offset padding;
  final CircuitComponent parent;

  final ComponentPort data;

  CircuitPort({
    required this.id,
    required this.relativePosition,
    required this.padding,
    required this.parent,
    required this.data,
  });

  Offset get absolutePosition => parent.position + relativePosition;
  Offset get absolutePositionWithOffset => absolutePosition + padding;

  @override
  Offset get position => absolutePosition;

  @override
  Size get size => const Size(5, 5);
}
