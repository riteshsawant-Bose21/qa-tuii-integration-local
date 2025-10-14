import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';
import 'package:fusion_launcher/features/wiring_design/util/wiring_serialization_util.dart';

import 'canvas_element.dart';
import 'circuit_component.dart';

class CircuitPort extends CanvasElement {
  @override
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

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      "position": <String, double>{
        "x": relativePosition.dx,
        "y": relativePosition.dy,
      },
      'parent': parent.id,
      'padding': <String, double>{
        'x': padding.dx,
        'y': padding.dy,
      },
    };
  }

  @override
  void restoreFromMap(Map<dynamic, dynamic> map) {
    relativePosition =
        WiringSerializationUtil.offsetDeserializer.deserialize(
          map['position'],
        ) ??
        relativePosition;
    padding =
        WiringSerializationUtil.offsetDeserializer.deserialize(
          map['padding'],
        ) ??
        padding;
  }
}
