part of 'peq_block.dart';

class _PeqGraphSection extends StatelessWidget {
  const _PeqGraphSection({super.key});

  @override
  Widget build(BuildContext context) {
    return PBSection(
      type: PBSectionType.left,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _PEQGraph(),
            ),
          ),
          FusionNeumorphicButton(
            text: "Add Band",
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 10),
            textStyle: context.textTheme.bodySmall,
            onTap: () {
              context.read<PEQController>().addBand();
            },
          ),
        ],
      ),
    );
  }
}

class _PEQGraph extends StatelessWidget {
  _PEQGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PEQController>(
      builder: (BuildContext context, PEQController controller, Widget? child) {
        final List<_PEQDataPoint> tableData = controller.tableMappedData;
        final (List<double> posX, List<double> amplitudes) = controller.graphData;

        return GestureDetector(
          onPanStart: (DragStartDetails details) {
            _handleDragStart(details, controller, tableData, context);
          },
          onPanUpdate: (DragUpdateDetails details) {
            _handleDragUpdate(details, controller, tableData, context);
          },
          onPanEnd: (DragEndDetails details) {
            _handleDragEnd();
          },
          child: CustomPaint(
            painter: _PEQGraphPainter(
              amplitudes: amplitudes,
              tableData: tableData,
              textColor: context.colorScheme.onSurface,
              gridColor: context.colorScheme.outline.withOpacity(0.3),
              curveColor: context.colorScheme.primary,
              graphBackgroundColor: context.colorScheme.elevation1,
              strokeDarkColor: context.colorScheme.strokeDark,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  int? _draggedBandIndex;

  void _handleDragStart(DragStartDetails details, PEQController controller, List<_PEQDataPoint> tableData, BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = details.localPosition;

    _draggedBandIndex = _findNearestBandPoint(localPosition, tableData, renderBox.size);
  }

  void _handleDragUpdate(DragUpdateDetails details, PEQController controller, List<_PEQDataPoint> tableData, BuildContext context) {
    if (_draggedBandIndex == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = details.localPosition;
    final Size size = renderBox.size;

    // Calculate graph boundaries
    const double leftPadding = 50.0;
    const double rightPadding = 20.0;
    const double topPadding = 20.0;
    const double bottomPadding = 40.0;

    final double graphWidth = size.width - leftPadding - rightPadding;
    final double graphHeight = size.height - topPadding - bottomPadding;
    final Rect graphRect = Rect.fromLTWH(leftPadding, topPadding, graphWidth, graphHeight);

    // Convert position to frequency and gain
    final double clampedX = localPosition.dx.clamp(graphRect.left, graphRect.right);
    final double clampedY = localPosition.dy.clamp(graphRect.top, graphRect.bottom);

    final double frequency = _xToFrequency(clampedX - graphRect.left, graphRect.width);
    final double gain = _yToDb(clampedY - graphRect.top, graphRect.height);

    // Update the controller
    controller.updateBandFrequency(_draggedBandIndex!, frequency);
    controller.updateGain(_draggedBandIndex!, gain);
  }

  void _handleDragEnd() {
    _draggedBandIndex = null;
  }

  int? _findNearestBandPoint(Offset position, List<_PEQDataPoint> tableData, Size size) {
    const double leftPadding = 50.0;
    const double rightPadding = 20.0;
    const double topPadding = 20.0;
    const double bottomPadding = 40.0;

    final double graphWidth = size.width - leftPadding - rightPadding;
    final double graphHeight = size.height - topPadding - bottomPadding;
    final Rect graphRect = Rect.fromLTWH(leftPadding, topPadding, graphWidth, graphHeight);

    const double touchRadius = 20.0; // Radius around point to detect touch

    for (int i = 0; i < tableData.length; i++) {
      final _PEQDataPoint dataPoint = tableData[i];

      // Skip bypassed bands
      if (dataPoint.bypass) continue;

      final double frequency = dataPoint.frequency.toDouble();
      final double gain = dataPoint.gain.toDouble();

      // Calculate position
      final double x = graphRect.left + _frequencyToX(frequency, graphRect.width);
      final double y = graphRect.top + _dbToY(gain, graphRect.height);

      // Check if touch is within radius of point
      final double distance = (Offset(x, y) - position).distance;
      if (distance <= touchRadius) {
        return i;
      }
    }

    return null;
  }

  double _frequencyToX(double frequency, double width) {
    const double minFreq = 20.0;
    const double maxFreq = 20000.0;
    final double logFreq = log(frequency.clamp(minFreq, maxFreq));
    final double logMin = log(minFreq);
    final double logMax = log(maxFreq);
    return ((logFreq - logMin) / (logMax - logMin)) * width;
  }

  double _dbToY(double db, double height) {
    const double minDb = -24.0;
    const double maxDb = 24.0;
    final double normalizedDb = (db.clamp(minDb, maxDb) - minDb) / (maxDb - minDb);
    return height * (1.0 - normalizedDb);
  }

  double _xToFrequency(double x, double width) {
    const double minFreq = 20.0;
    const double maxFreq = 20000.0;
    final double logMin = log(minFreq);
    final double logMax = log(maxFreq);
    final double normalizedX = (x / width).clamp(0.0, 1.0);
    final double logFreq = logMin + (logMax - logMin) * normalizedX;
    return exp(logFreq).clamp(minFreq, maxFreq);
  }

  double _yToDb(double y, double height) {
    const double minDb = -24.0;
    const double maxDb = 24.0;
    final double normalizedY = (1.0 - (y / height)).clamp(0.0, 1.0);
    return (minDb + (maxDb - minDb) * normalizedY).clamp(minDb, maxDb);
  }
}

class _PEQGraphPainter extends CustomPainter {
  final List<double> amplitudes;
  final List<_PEQDataPoint> tableData;
  final Color textColor;
  final Color gridColor;
  final Color curveColor;
  final Color graphBackgroundColor;
  final Color strokeDarkColor;

  const _PEQGraphPainter({
    required this.amplitudes,
    required this.tableData,
    required this.textColor,
    required this.gridColor,
    required this.curveColor,
    required this.graphBackgroundColor,
    required this.strokeDarkColor,
  });

  static const double minFreq = 20.0;
  static const double maxFreq = 20000.0;
  static const double minDb = -24.0;
  static const double maxDb = 24.0;
  static const double leftPadding = 50.0;
  static const double rightPadding = 20.0;
  static const double topPadding = 20.0;
  static const double bottomPadding = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final double graphWidth = size.width - leftPadding - rightPadding;
    final double graphHeight = size.height - topPadding - bottomPadding;
    final Rect graphRect = Rect.fromLTWH(leftPadding, topPadding, graphWidth, graphHeight);

    // Draw background
    final Paint backgroundPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Draw graph area background
    final Paint graphBackgroundPaint = Paint()..color = graphBackgroundColor;
    canvas.drawRect(graphRect, graphBackgroundPaint);

    // Draw bounding box around graph area
    final Paint boundingBoxPaint =
        Paint()
          ..color = strokeDarkColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    canvas.drawRect(graphRect, boundingBoxPaint);

    // Draw grid lines and labels
    _drawGrid(canvas, size, graphRect);

    // Draw axes
    _drawAxes(canvas, size, graphRect);

    // Draw frequency response curve
    if (amplitudes.isNotEmpty) {
      _drawFrequencyResponse(canvas, graphRect);
    }

    // Draw band points
    _drawBandPoints(canvas, graphRect);
  }

  void _drawGrid(Canvas canvas, Size size, Rect graphRect) {
    // Major grid lines
    final Paint gridPaint =
        Paint()
          ..color = strokeDarkColor
          ..strokeWidth = 0.5;

    // Minor grid lines (thinner and more transparent)
    final Paint minorGridPaint =
        Paint()
          ..color = strokeDarkColor
          ..strokeWidth = 0.25;

    // Minor vertical grid lines (frequency)
    final List<double> minorFreqGridValues = <double>[];

    // Between 20-100Hz: every 10Hz
    for (int i = 30; i < 100; i += 10) {
      minorFreqGridValues.add(i.toDouble());
    }

    // Between 100-1000Hz: every 100Hz
    for (int i = 300; i < 1000; i += 100) {
      minorFreqGridValues.add(i.toDouble());
    }

    // Between 1000-10000Hz: every 1000Hz
    for (int i = 3000; i < 10000; i += 1000) {
      minorFreqGridValues.add(i.toDouble());
    }

    for (final double freq in minorFreqGridValues) {
      if (freq >= minFreq && freq <= maxFreq) {
        final double x = graphRect.left + _frequencyToX(freq, graphRect.width);
        canvas.drawLine(
          Offset(x, graphRect.top),
          Offset(x, graphRect.bottom),
          minorGridPaint,
        );
      }
    }

    // Major vertical grid lines (frequency)
    final List<double> freqGridValues = <double>[50, 100, 200, 500, 1000, 2000, 5000, 10000];
    for (final double freq in freqGridValues) {
      if (freq >= minFreq && freq <= maxFreq) {
        final double x = graphRect.left + _frequencyToX(freq, graphRect.width);
        canvas.drawLine(
          Offset(x, graphRect.top),
          Offset(x, graphRect.bottom),
          gridPaint,
        );
      }
    }

    // Horizontal grid lines (dB)
    final List<double> dbGridValues = <double>[-20, -15, -10, -5, 0, 5, 10, 15, 20];
    for (final double db in dbGridValues) {
      if (db >= minDb && db <= maxDb) {
        final double y = graphRect.top + _dbToY(db, graphRect.height);
        canvas.drawLine(
          Offset(graphRect.left, y),
          Offset(graphRect.right, y),
          gridPaint,
        );
      }
    }
  }

  void _drawAxes(Canvas canvas, Size size, Rect graphRect) {
    final Paint axisPaint =
        Paint()
          ..color = strokeDarkColor
          ..strokeWidth = 1.0;

    // Draw axes
    canvas.drawLine(
      Offset(graphRect.left, graphRect.top),
      Offset(graphRect.left, graphRect.bottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(graphRect.left, graphRect.bottom),
      Offset(graphRect.right, graphRect.bottom),
      axisPaint,
    );

    // Draw frequency labels
    final TextStyle labelStyle = TextStyle(
      color: textColor,
      fontSize: 10,
    );

    final List<(double freq, String label)> freqLabels = <(double, String)>[
      (20, '20'),
      (50, '50'),
      (100, '100'),
      (200, '200'),
      (500, '500'),
      (1000, '1k'),
      (2000, '2k'),
      (5000, '5k'),
      (10000, '10k'),
      (20000, '20k'),
    ];

    for (final (double freq, String label) in freqLabels) {
      if (freq >= minFreq && freq <= maxFreq) {
        final double x = graphRect.left + _frequencyToX(freq, graphRect.width);
        final TextPainter textPainter = TextPainter(
          text: TextSpan(text: label, style: labelStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, graphRect.bottom + 5),
        );
      }
    }

    // Draw dB labels
    final List<int> dbLabels = <int>[-20, -10, 0, 10, 20];
    for (final int db in dbLabels) {
      if (db >= minDb && db <= maxDb) {
        final double y = graphRect.top + _dbToY(db.toDouble(), graphRect.height);
        final TextPainter textPainter = TextPainter(
          text: TextSpan(text: '${db}dB', style: labelStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(leftPadding - textPainter.width - 5, y - textPainter.height / 2),
        );
      }
    }

    // Draw axis labels
    final TextStyle axisLabelStyle = TextStyle(
      color: textColor,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    // X-axis label
    final TextPainter xLabelPainter = TextPainter(
      text: TextSpan(text: 'Frequency (Hz)', style: axisLabelStyle),
      textDirection: TextDirection.ltr,
    );
    xLabelPainter.layout();
    xLabelPainter.paint(
      canvas,
      Offset(
        graphRect.center.dx - xLabelPainter.width / 2,
        size.height - 15,
      ),
    );

    // Y-axis label (rotated)
    final TextPainter yLabelPainter = TextPainter(
      text: TextSpan(text: 'Gain (dB)', style: axisLabelStyle),
      textDirection: TextDirection.ltr,
    );
    yLabelPainter.layout();

    canvas.save();
    canvas.translate(0, graphRect.center.dy + yLabelPainter.width / 2);
    canvas.rotate(-pi / 2);
    yLabelPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawFrequencyResponse(Canvas canvas, Rect graphRect) {
    final Paint curvePaint =
        Paint()
          ..color = curveColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final Path path = Path();
    bool firstPoint = true;

    // Generate frequency points for smooth curve
    const int numPoints = 1000;
    final List<double> logFreqs = List<double>.generate(numPoints, (int i) {
      final double logMin = log(minFreq);
      final double logMax = log(maxFreq);
      final double logFreq = logMin + (logMax - logMin) * i / (numPoints - 1);
      return exp(logFreq);
    });

    for (int i = 0; i < logFreqs.length; i++) {
      final double freq = logFreqs[i];
      final double amplitude = _getAmplitudeAtFrequency(freq);

      final double x = graphRect.left + _frequencyToX(freq, graphRect.width);
      final double y = graphRect.top + _dbToY(amplitude, graphRect.height);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, curvePaint);
  }

  double _getAmplitudeAtFrequency(double targetFreq) {
    // Since amplitudes correspond to the calculated response across frequency spectrum,
    // we need to map the target frequency to the correct index in the amplitudes array
    if (amplitudes.isEmpty) return 0.0;

    // Calculate the index based on logarithmic frequency distribution
    final double logMin = log(minFreq);
    final double logMax = log(maxFreq);
    final double logTarget = log(targetFreq.clamp(minFreq, maxFreq));

    final double normalizedPosition = (logTarget - logMin) / (logMax - logMin);
    final double exactIndex = normalizedPosition * (amplitudes.length - 1);

    final int lowerIndex = exactIndex.floor().clamp(0, amplitudes.length - 1);
    final int upperIndex = exactIndex.ceil().clamp(0, amplitudes.length - 1);

    if (lowerIndex == upperIndex) {
      return amplitudes[lowerIndex];
    }

    // Linear interpolation between the two closest points
    final double fraction = exactIndex - lowerIndex;
    return amplitudes[lowerIndex] + (amplitudes[upperIndex] - amplitudes[lowerIndex]) * fraction;
  }

  double _frequencyToX(double frequency, double width) {
    final double logFreq = log(frequency.clamp(minFreq, maxFreq));
    final double logMin = log(minFreq);
    final double logMax = log(maxFreq);
    return ((logFreq - logMin) / (logMax - logMin)) * width;
  }

  double _dbToY(double db, double height) {
    final double normalizedDb = (db.clamp(minDb, maxDb) - minDb) / (maxDb - minDb);
    return height * (1.0 - normalizedDb);
  }

  void _drawBandPoints(Canvas canvas, Rect graphRect) {
    const double pointRadius = 12.0;
    const double textSize = 10.0;

    final Paint circlePaint =
        Paint()
          ..color = curveColor
          ..style = PaintingStyle.fill;

    final Paint borderPaint =
        Paint()
          ..color = strokeDarkColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    final TextStyle pointTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: textSize,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < tableData.length; i++) {
      final _PEQDataPoint dataPoint = tableData[i];

      // Skip bypassed bands
      if (dataPoint.bypass) continue;

      final double frequency = dataPoint.frequency.toDouble();
      final double gain = dataPoint.gain.toDouble();

      // Calculate position
      final double x = graphRect.left + _frequencyToX(frequency, graphRect.width);
      final double y = graphRect.top + _dbToY(gain, graphRect.height);

      // Check if point is within graph bounds
      if (x >= graphRect.left && x <= graphRect.right && y >= graphRect.top && y <= graphRect.bottom) {
        // Draw circle background
        canvas.drawCircle(Offset(x, y), pointRadius, circlePaint);

        // Draw border
        canvas.drawCircle(Offset(x, y), pointRadius, borderPaint);

        // Draw index text
        final String indexText = (i + 1).toString();
        final TextPainter textPainter = TextPainter(
          text: TextSpan(text: indexText, style: pointTextStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();

        final Offset textOffset = Offset(
          x - textPainter.width / 2,
          y - textPainter.height / 2,
        );

        textPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PEQGraphPainter oldDelegate) {
    return amplitudes != oldDelegate.amplitudes ||
        tableData != oldDelegate.tableData ||
        textColor != oldDelegate.textColor ||
        gridColor != oldDelegate.gridColor ||
        curveColor != oldDelegate.curveColor ||
        graphBackgroundColor != oldDelegate.graphBackgroundColor ||
        strokeDarkColor != oldDelegate.strokeDarkColor;
  }
}
