part of 'gate_block.dart';

class _GateGraph extends StatelessWidget {
  const _GateGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GateController>(
      builder: (
        BuildContext context,
        GateController controller,
        Widget? child,
      ) {
        final List<GraphPoint> points = controller.getGraphPoints();
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Graph area with padding for external labels
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 60.0, // Space for Y-axis labels and title
                      right: 16.0, // Right padding
                      top: 16.0, // Top padding
                      bottom: 60.0, // Space for X-axis labels and title
                    ),
                    child: _GateGraphPainter(
                      points: points,
                      onPointChanged: controller.onGraphPointChanged,
                    ),
                  ),
                ),
              ),
              // Remove the bottom labels as they're now part of the graph
            ],
          ),
        );
      },
    );
  }
}

class _GateGraphPainter extends StatefulWidget {
  const _GateGraphPainter({
    super.key,
    required this.points,
    required this.onPointChanged,
  });

  final List<GraphPoint> points;
  final Function(int index, num value, DragDirection direction) onPointChanged;

  @override
  State<_GateGraphPainter> createState() => _GateGraphPainterState();
}

class _GateGraphPainterState extends State<_GateGraphPainter> {
  int? draggedPointIndex;
  int? tappedPointIndex;
  Offset? lastPanPosition;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        'gate_graph',
      ),
      child: GestureDetector(
        onTap: () {
          // setState(() {
          //   tappedPointIndex = null;
          // });
        },
        onTapDown: (TapDownDetails details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final Offset localPosition = renderBox.globalToLocal(
            details.globalPosition,
          );

          // Find the closest draggable point
          final int? pointIndex = _findClosestDraggablePoint(
            localPosition,
            renderBox.size,
          );
          if (pointIndex != null) {
            setState(() {
              tappedPointIndex = pointIndex;
            });
          }
        },
        onPanStart: (DragStartDetails details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final Offset localPosition = renderBox.globalToLocal(
            details.globalPosition,
          );

          // Find the closest draggable point
          draggedPointIndex = _findClosestDraggablePoint(
            localPosition,
            renderBox.size,
          );
          if (draggedPointIndex != null) {
            setState(() {
              tappedPointIndex =
                  null; // Clear tap highlight when dragging starts
            });
          }
          lastPanPosition = localPosition;
        },
        onPanUpdate: (DragUpdateDetails details) {
          if (draggedPointIndex != null) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final Offset localPosition = renderBox.globalToLocal(
              details.globalPosition,
            );
            final Size size = renderBox.size;

            // Convert current pixel position to dB values
            final double normalizedX = localPosition.dx / size.width;
            final double normalizedY =
                1.0 - (localPosition.dy / size.height); // Invert Y axis

            final double dbX =
                (normalizedX * 80.0) - 80.0; // Convert to -80 to 0 dB range
            final double dbY =
                (normalizedY * 80.0) - 80.0; // Convert to -80 to 0 dB range

            if (lastPanPosition != null) {
              final Offset delta = localPosition - lastPanPosition!;
              final double deltaX = delta.dx.abs();
              final double deltaY = delta.dy.abs();

              // Determine drag direction and update accordingly
              if (deltaX > deltaY) {
                // Horizontal drag
                widget.onPointChanged(
                  draggedPointIndex!,
                  dbX.clamp(-80.0, 0.0),
                  DragDirection.horizontal,
                );
              } else {
                // Vertical drag
                widget.onPointChanged(
                  draggedPointIndex!,
                  dbY.clamp(-80.0, 0.0),
                  DragDirection.vertical,
                );
              }
            }

            lastPanPosition = localPosition;
          }
        },
        onPanEnd: (DragEndDetails details) {
          setState(() {
            draggedPointIndex = null;
          });
          lastPanPosition = null;
        },
        child: CustomPaint(
          painter: _GateCurvePainter(
            points: widget.points,
            draggedPointIndex: draggedPointIndex,
            tappedPointIndex: tappedPointIndex,
            theme: Theme.of(context),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  int? _findClosestDraggablePoint(Offset position, Size size) {
    const double hitRadius = 20.0;
    double closestDistance = double.infinity;
    int? closestIndex;

    for (int i = 0; i < widget.points.length; i++) {
      if (!widget.points[i].isDraggable) continue;

      final GraphPoint point = widget.points[i];
      final Offset pointPosition = _dbToPixel(point.x, point.y, size);
      final double distance = (position - pointPosition).distance;

      if (distance < hitRadius && distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  Offset _dbToPixel(num dbX, num dbY, Size size) {
    // Convert dB values (-80 to 0) to pixel coordinates
    final double normalizedX = ((dbX) + 80) / 80; // 0 to 1
    final double normalizedY = 1 - ((dbY) + 80) / 80; // 0 to 1, inverted

    return Offset(
      normalizedX * size.width,
      normalizedY * size.height,
    );
  }
}

class _GateCurvePainter extends CustomPainter {
  const _GateCurvePainter({
    required this.points,
    required this.theme,
    this.draggedPointIndex,
    this.tappedPointIndex,
  });

  final List<GraphPoint> points;
  final ThemeData theme;
  final int? draggedPointIndex;
  final int? tappedPointIndex;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoundaryLines(canvas, size);
    _drawGrid(canvas, size);
    _drawCurve(canvas, size);
    _drawPoints(canvas, size);
    _drawAxisLabels(canvas, size);
  }

  void _drawBoundaryLines(Canvas canvas, Size size) {
    final Paint boundaryPaint =
        Paint()
          ..color = theme.colorScheme.strokeLight
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
    final Paint fillPaint = Paint()..color = theme.colorScheme.elevation1;

    // Draw outer boundary rectangle
    canvas.drawRect(Offset.zero & size, boundaryPaint);
    canvas.drawRect(Offset.zero & size, fillPaint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final Paint gridPaint =
        Paint()
          ..color = theme.colorScheme.strokeLight
          ..strokeWidth = 1;

    // Draw vertical grid lines (every 10 dB)
    for (int db = -80; db <= 0; db += 20) {
      final double x = ((db + 80) / 80) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal grid lines (every 10 dB)
    for (int db = -80; db <= 0; db += 20) {
      final double y = (1 - (db + 80) / 80) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawCurve(Canvas canvas, Size size) {
    final Paint curvePaint =
        Paint()
          ..color = theme.colorScheme.primary
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final Path path = Path();

    for (int i = 0; i < points.length; i++) {
      final Offset pixelPoint = _dbToPixel(points[i].x, points[i].y, size);

      if (i == 0) {
        path.moveTo(pixelPoint.dx, pixelPoint.dy);
      } else {
        path.lineTo(pixelPoint.dx, pixelPoint.dy);
      }
    }

    canvas.drawPath(path, curvePaint);
  }

  void _drawPoints(Canvas canvas, Size size) {
    final Paint pointPaint =
        Paint()
          ..color = theme.colorScheme.primary
          ..style = PaintingStyle.fill;

    final Paint draggedPointPaint =
        Paint()
          ..color = theme.colorScheme.secondary
          ..style = PaintingStyle.fill;

    final Paint tappedPointPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final Paint strokePaint =
        Paint()
          ..color = theme.colorScheme.surface
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      if (!points[i].isDraggable) continue;

      final Offset pixelPoint = _dbToPixel(points[i].x, points[i].y, size);
      final bool isDragged = i == draggedPointIndex;
      final bool isTapped = i == tappedPointIndex;
      const double radius = 6.0;

      // Draw point background
      canvas.drawCircle(pixelPoint, radius + 1, strokePaint);

      // Draw point with appropriate color
      Paint selectedPaint;
      if (isDragged) {
        selectedPaint = draggedPointPaint;
      } else if (isTapped) {
        selectedPaint = tappedPointPaint;
      } else {
        selectedPaint = pointPaint;
      }

      canvas.drawCircle(pixelPoint, radius, selectedPaint);
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size) {
    final TextStyle labelStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.textGrey,
    );

    final TextStyle axisLabelStyle = theme.textTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.bold,
    );

    const double labelPadding = 22.0;
    const double axisTitlePadding = 8.0;

    // Draw dB value labels on X axis (bottom, outside bounds)
    for (int db = -80; db <= 0; db += 20) {
      final double x = ((db + 80) / 80) * size.width;
      final TextPainter painter = TextPainter(
        text: TextSpan(text: '$db', style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(x - painter.width / 2, size.height + axisTitlePadding),
      );
    }

    // Draw dB value labels on Y axis (left, outside bounds)
    for (int db = -80; db <= 0; db += 20) {
      final double y = (1 - (db + 80) / 80) * size.height;
      final TextPainter painter = TextPainter(
        text: TextSpan(text: '$db', style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(-painter.width - axisTitlePadding, y - painter.height / 2),
      );
    }

    // Draw X-axis title "In (dBFS)" at bottom center
    final TextPainter xAxisTitlePainter = TextPainter(
      text: TextSpan(text: 'In (dBFS)', style: axisLabelStyle),
      textDirection: TextDirection.ltr,
    );
    xAxisTitlePainter.layout();
    xAxisTitlePainter.paint(
      canvas,
      Offset(
        (size.width - xAxisTitlePainter.width) / 2,
        size.height + labelPadding + axisTitlePadding,
      ),
    );

    // Draw Y-axis title "Out (dBFS)" vertically on the left
    final TextPainter yAxisTitlePainter = TextPainter(
      text: TextSpan(text: 'Out (dBFS)', style: axisLabelStyle),
      textDirection: TextDirection.ltr,
    );
    yAxisTitlePainter.layout();

    // Save the canvas state before rotation
    canvas.save();
    // Translate to the desired position and rotate -90 degrees
    // Position it further left to avoid overlap with value labels
    canvas.translate(
      -labelPadding - axisTitlePadding - 30,
      size.height / 2 + yAxisTitlePainter.width / 2,
    );
    canvas.rotate(-3.14159 / 2); // -90 degrees in radians
    yAxisTitlePainter.paint(canvas, Offset.zero);
    // Restore the canvas state
    canvas.restore();
  }

  Offset _dbToPixel(num dbX, num dbY, Size size) {
    final double normalizedX = ((dbX) + 80) / 80;
    final double normalizedY = 1 - ((dbY) + 80) / 80;

    return Offset(
      normalizedX * size.width,
      normalizedY * size.height,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
