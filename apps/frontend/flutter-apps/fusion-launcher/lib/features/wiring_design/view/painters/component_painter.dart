import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';
import 'package:fusion_launcher/features/wiring_design/model/model.dart';
import 'package:fusion_launcher/features/wiring_design/util/canvas_util.dart';
import 'package:fusion_launcher/features/wiring_design/view/painters/base_painter.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

part './component/base_component_painter.dart';
part './component/device_schematic_component_painter.dart';
part './component/source_component_painter.dart';
part './component/speaker_component_painter.dart';

class ComponentPainter extends BasePainter {
  final CircuitComponent component;
  ComponentPainter({
    required this.component,
    required super.controller,
    required super.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ComponentDataPainter comPainter = switch (component.data) {
      DeviceSchematicComponentData() => DeviceSchematicComponentPainter(
        component,
        this,
      ),
      SourceComponentData() => SourceComponentPainter(
        component: component,
        painter: this,
      ),
      SpeakerComponentData() => SpeakerComponentPainter(
        component: component,
        painter: this,
      ),
      _ => BaseComponentPainter(component: component, painter: this),
    };

    comPainter.paint(canvas, size);
  }

  @override
  CanvasElement? isHit(Offset position) {
    for (final CircuitPort port in component.ports) {
      final Rect portRect = Rect.fromCircle(
        center: component.position + port.relativePosition,
        radius: WiringViewConstants.portRadius,
      );
      if (portRect.contains(position)) {
        return port;
      }
    }
    final Rect rect = component.position & component.size;
    if (rect.contains(position)) {
      return component;
    }
    return null;
  }

  bool hasConnection(CircuitPort port) {
    return controller.hasConnection(port);
  }
}

abstract class ComponentDataPainter {
  void paint(Canvas canvas, Size size);
}
