part of '../component_painter.dart';

class DeviceSchematicComponentPainter extends ComponentDataPainter {
  final CircuitComponent component;
  final ComponentPainter painter;

  DeviceSchematicComponentPainter(this.component, this.painter);
  @override
  void paint(Canvas canvas, Size size) {
    /// -------------------------------------------------------------
    ///   Draw Component
    /// -------------------------------------------------------------

    ///
    /// Background
    ///
    final Rect rect = component.position & component.size;

    if (painter.controller.selectedElement == component) {
      canvas.drawShadow(Path()..addRect(rect), Colors.black, 20, false);
    }
    canvas.drawRect(rect, Paint()..color = painter.colorScheme.componentBG);
    canvas.drawRect(
      rect,
      Paint()
        ..color = painter.colorScheme.componentBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    ///
    /// Heading
    ///
    final Rect headingRect =
        component.position & Size(component.size.width, 50);
    canvas.drawRect(
      headingRect,
      Paint()..color = painter.colorScheme.componentHeadingBG,
    );
    painter.drawImage(
      canvas: canvas,
      path: component.data.image ?? "",
      rect: headingRect,
    );

    ///
    /// Body
    ///

    painter.drawText(
      canvas: canvas,
      text: component.data.label,
      style: TextStyle(
        color: painter.colorScheme.componentFG,
        // color:
        fontSize: rect.width * 0.05,
        fontWeight: FontWeight.w600,
      ),
      position: rect.center,
      maxWidth: rect.width * 0.35,
    );

    /// -------------------------------------------------------------
    ///   Draw Ports
    /// -------------------------------------------------------------
    final Paint connectedPortPaint =
        Paint()
          ..color = painter.colorScheme.activePortBG
          ..style = PaintingStyle.fill;
    final Paint freePortPaint =
        Paint()
          ..color = painter.colorScheme.inactivePortBG
          ..strokeWidth = WiringViewConstants.portRadius * 0.10
          ..style = PaintingStyle.stroke;

    if (component.inputPorts.isNotEmpty) {
      painter.drawText(
        canvas: canvas,
        text: "INPUT",
        position:
            component.inputPorts.first.absolutePosition +
            const Offset(WiringViewConstants.portRadius * 2, 0),
        positionAlignment: Alignment.centerLeft,
        style: TextStyle(
          color: painter.colorScheme.componentFG,
          // color:
          fontSize: rect.width * 0.035,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (component.outputPorts.isNotEmpty) {
      painter.drawText(
        canvas: canvas,
        text: "OUTPUT",
        position:
            component.outputPorts.first.absolutePosition -
            const Offset(WiringViewConstants.portRadius * 2, 0),
        positionAlignment: Alignment.centerRight,
        style: TextStyle(
          color: painter.colorScheme.componentFG,
          // color:
          fontSize: rect.width * 0.035,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    for (final CircuitPort port in <CircuitPort>[
      ...component.inputPorts,
      ...component.outputPorts,
    ]) {
      final Path portPath = Path();

      /// Port
      portPath.addOval(
        Rect.fromCircle(
          center: port.absolutePosition,
          radius: WiringViewConstants.portRadius,
        ),
      );
      final bool hasConnection = painter.hasConnection(port);
      canvas.drawPath(
        portPath,
        hasConnection ? connectedPortPaint : freePortPaint,
      );

      /// Port Label
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: port.data.label ?? Random().nextInt(20).toString(),
          style: TextStyle(
            color:
                hasConnection
                    ? painter.colorScheme.activePortFG
                    : painter.colorScheme.inactivePortFG,
            fontSize: WiringViewConstants.portRadius * 0.75,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Align text to center
      tp.paint(
        canvas,
        Offset(
          port.absolutePosition.dx - tp.width / 2,
          port.absolutePosition.dy - tp.height / 2,
        ),
      );
    }
  }
}
