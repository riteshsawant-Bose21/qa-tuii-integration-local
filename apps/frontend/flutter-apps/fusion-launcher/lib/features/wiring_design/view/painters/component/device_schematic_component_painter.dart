part of '../component_painter.dart';

class DeviceSchematicComponentPainter extends ComponentDataPainter {
  final CircuitComponent component;
  final ComponentPainter painter;

  DeviceSchematicComponentPainter(this.component, this.painter);
  @override
  void paint(Canvas canvas, Size size) {
    /// **************************************************************************************************************************
    ///
    ///
    ///   Draw Component
    ///
    ///
    /// **************************************************************************************************************************

    ///--------------------------------------------------------
    /// Background
    ///--------------------------------------------------------
    final Rect rect = component.position & component.size;

    if (painter.isSelected(component)) {
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

    ///--------------------------------------------------------
    /// Heading
    ///--------------------------------------------------------
    final Rect headingRect = component.position & Size(component.size.width, 50);
    canvas.drawRect(
      headingRect,
      Paint()..color = painter.colorScheme.componentHeadingBG,
    );
    painter.drawImage(
      canvas: canvas,
      path: component.data.image ?? "",
      rect: headingRect,
    );

    ///--------------------------------------------------------
    /// Body
    ///--------------------------------------------------------

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

    /// **************************************************************************************************************************
    ///
    ///
    ///   Draw Input/Output Ports
    ///
    ///
    /// **************************************************************************************************************************
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
        position: component.inputPorts.first.absolutePosition + const Offset(WiringViewConstants.portRadius * 2, 0),
        positionAlignment: Alignment.centerLeft,
        style: TextStyle(
          color: painter.colorScheme.componentFG,
          fontSize: rect.width * 0.035,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (component.outputPorts.isNotEmpty) {
      painter.drawText(
        canvas: canvas,
        text: "OUTPUT",
        position: component.outputPorts.first.absolutePosition - const Offset(WiringViewConstants.portRadius * 2, 0),
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

      final bool hasConnection = painter.hasConnection(port);
      if (port.data.image != null) {
        painter.drawImage(
          canvas: canvas,
          path: port.data.image!,
          rect: Rect.fromCircle(
            center: port.absolutePosition,
            radius: WiringViewConstants.portRadius,
          ),
        );
        final PortPosition? position2 = port.data.position;
        painter.drawText(
          canvas: canvas,
          text: port.data.label ?? "",
          position:
              port.absolutePosition +
              Offset(
                (position2 == PortPosition.bottomLeft || position2 == PortPosition.topLeft)
                    ? WiringViewConstants.portRadius * 1.5
                    : -WiringViewConstants.portRadius * 1.5,
                0,
              ),
          positionAlignment: (position2 == PortPosition.bottomLeft || position2 == PortPosition.topLeft) ? Alignment.centerLeft : Alignment.centerRight,
        );
      } else {
        portPath.addOval(
          Rect.fromCircle(
            center: port.absolutePosition,
            radius: WiringViewConstants.portRadius,
          ),
        );

        /// Port Label
        final TextPainter tp = TextPainter(
          text: TextSpan(
            text: port.data.label ?? Random().nextInt(20).toString(),
            style: TextStyle(
              color: hasConnection ? painter.colorScheme.activePortFG : painter.colorScheme.inactivePortFG,
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
      canvas.drawPath(
        portPath,
        hasConnection ? connectedPortPaint : freePortPaint,
      );
    }

    /// --------------------------------------------------------------------------------------------------------------------------
    ///   Draw Com Ports
    /// --------------------------------------------------------------------------------------------------------------------------
    for (final CircuitPort port in <CircuitPort>[
      ...component.otherPorts,
    ]) {
      if (port.data.image != null) {
        painter.drawImage(
          canvas: canvas,
          path: port.data.image!,
          rect: Rect.fromCircle(
            center: port.absolutePosition,
            radius: WiringViewConstants.portRadius,
          ),
        );
      } else {
        final Path portPath = Path();
        portPath.addOval(
          Rect.fromCircle(
            center: port.absolutePosition,
            radius: WiringViewConstants.portRadius,
          ),
        );
        final bool hasConnection = painter.hasConnection(port);
        final Paint portPaint = hasConnection ? connectedPortPaint : freePortPaint;
        canvas.drawPath(
          portPath,
          portPaint,
        );
        painter.drawText(
          canvas: canvas,
          text: port.data.label ?? port.data.index.toString(),
          maxWidth: WiringViewConstants.comPortWidth,
          positionAlignment: Alignment.center,
          position: port.absolutePosition,
        );
      }

      final PortPosition? position2 = port.data.position;
      painter.drawText(
        canvas: canvas,
        text: port.data.description ?? port.data.type.name,
        maxWidth: WiringViewConstants.comPortWidth,
        positionAlignment: switch (position2) {
          PortPosition.bottomRight => Alignment.bottomRight,
          PortPosition.footerLeft || PortPosition.footerCenter || PortPosition.footerRight => Alignment.bottomCenter,
          _ => Alignment.centerLeft,
        },
        position: switch (position2) {
          PortPosition.bottomRight => Offset(
            port.absolutePosition.dx - WiringViewConstants.portDimension,
            port.absolutePosition.dy + WiringViewConstants.portRadius / 2,
          ),
          PortPosition.footerLeft || PortPosition.footerCenter || PortPosition.footerRight => Offset(
            port.absolutePosition.dx,
            port.absolutePosition.dy - WiringViewConstants.portRadius - 5,
          ),
          _ => Offset(
            WiringViewConstants.portRadius * 2 + port.absolutePosition.dx,
            port.absolutePosition.dy,
          ),
        },
      );

      final PortType type = port.data.type;
      if (type.isEthernet) {
        final Color color = painter.colorScheme.switchWireColor;
        final Offset center = port.absolutePosition + const Offset(0, 75);
        canvas.drawLine(
          center - const Offset(0, WiringViewConstants.portRadius),
          port.absolutePosition + const Offset(0, WiringViewConstants.portRadius),
          Paint()
            ..color = color
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
        painter.drawImage(
          canvas: canvas,
          path: 'assets/icons/wiring_ports/ethernet.png',
          paint:
              Paint()
                ..colorFilter = ColorFilter.mode(
                  color,
                  BlendMode.srcIn,
                ),
          rect: Rect.fromCircle(
            center: center,
            radius: WiringViewConstants.portRadius,
          ),
        );
        painter.drawText(
          canvas: canvas,
          text: "SWITCH",
          position: center + const Offset(0, WiringViewConstants.portRadius),
          positionAlignment: Alignment.topCenter,
          style: TextStyle(
            color: color,
          ),
        );
      }
    }
  }
}
