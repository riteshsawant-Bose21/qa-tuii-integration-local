import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class FloorPlanCalibrationDialog extends StatelessWidget {
  final ui.Image floorPlanImage;
  final Function(CalibrationData) onCalibrationComplete;
  final VoidCallback? onCancel;

  const FloorPlanCalibrationDialog({
    Key? key,
    required this.floorPlanImage,
    required this.onCalibrationComplete,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        width: 800,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FloorPlanCalibration(
            floorPlanImage: floorPlanImage,
            onCalibrationComplete: onCalibrationComplete,
            onCancel: onCancel,
          ),
        ),
      ),
    );
  }
}

class FloorPlanCalibration extends StatefulWidget {
  final ui.Image floorPlanImage;
  final Function(CalibrationData) onCalibrationComplete;
  final VoidCallback? onCancel;

  const FloorPlanCalibration({
    Key? key,
    required this.floorPlanImage,
    required this.onCalibrationComplete,
    this.onCancel,
  }) : super(key: key);

  @override
  State<FloorPlanCalibration> createState() => _FloorPlanCalibrationState();
}

class _FloorPlanCalibrationState extends State<FloorPlanCalibration> {
  Offset? _startPointNormalized;
  Offset? _endPointNormalized;

  Offset? _startPointDisplay;
  Offset? _endPointDisplay;

  final TextEditingController _distanceController = TextEditingController();
  MeasurementUnit _selectedUnit = MeasurementUnit.meters;
  bool _isDrawing = false;

  Rect? _currentImageRect;

  @override
  void initState() {
    super.initState();
    _distanceController.text = '1';
    _distanceController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  Offset? _screenToNormalized(Offset screenPoint) {
    if (_currentImageRect == null) return null;

    final double x = (screenPoint.dx - _currentImageRect!.left) / _currentImageRect!.width;
    final double y = (screenPoint.dy - _currentImageRect!.top) / _currentImageRect!.height;

    // Clamp to valid range
    return Offset(
      x.clamp(0.0, 1.0),
      y.clamp(0.0, 1.0),
    );
  }

  Offset? _normalizedToScreen(Offset normalizedPoint) {
    if (_currentImageRect == null) return null;

    return Offset(
      _currentImageRect!.left + normalizedPoint.dx * _currentImageRect!.width,
      _currentImageRect!.top + normalizedPoint.dy * _currentImageRect!.height,
    );
  }

  Offset _normalizedToImagePixels(Offset normalizedPoint) {
    return Offset(
      normalizedPoint.dx * widget.floorPlanImage.width,
      normalizedPoint.dy * widget.floorPlanImage.height,
    );
  }

  void _onTapDown(TapDownDetails details) {
    final Offset? normalizedPoint = _screenToNormalized(details.localPosition);
    if (normalizedPoint == null) return;

    if (_startPointNormalized == null) {
      setState(() {
        _startPointNormalized = normalizedPoint;
        _startPointDisplay = details.localPosition;
        _endPointNormalized = null;
        _endPointDisplay = null;
        _isDrawing = true;
      });
    } else if (_isDrawing) {
      setState(() {
        _endPointNormalized = normalizedPoint;
        _endPointDisplay = details.localPosition;
        _isDrawing = false;
      });
    } else {
      setState(() {
        _startPointNormalized = normalizedPoint;
        _startPointDisplay = details.localPosition;
        _endPointNormalized = null;
        _endPointDisplay = null;
        _isDrawing = true;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDrawing && _startPointNormalized != null) {
      final Offset? normalizedPoint = _screenToNormalized(details.localPosition);
      if (normalizedPoint == null) return;

      setState(() {
        _endPointNormalized = normalizedPoint;
        _endPointDisplay = details.localPosition;
      });
    }
  }

  void _onHover(PointerHoverEvent event) {
    if (_isDrawing && _startPointNormalized != null) {
      final Offset? normalizedPoint = _screenToNormalized(event.localPosition);
      if (normalizedPoint == null) return;

      setState(() {
        _endPointNormalized = normalizedPoint;
        _endPointDisplay = event.localPosition;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDrawing && _startPointNormalized != null && _endPointNormalized != null) {
      setState(() {
        _isDrawing = false;
      });
    }
  }

  Widget _buildCalibrationInfo() {
    if (_startPointNormalized == null || _endPointNormalized == null) {
      return const SizedBox.shrink();
    }

    final Offset startImagePixels = _normalizedToImagePixels(_startPointNormalized!);
    final Offset endImagePixels = _normalizedToImagePixels(_endPointNormalized!);
    final Offset diff = endImagePixels - startImagePixels;
    final double pixelDistance = diff.distance;

    final double realDistance = double.tryParse(_distanceController.text) ?? 1.0;
    final double pixelsPerUnit = realDistance > 0 ? pixelDistance / realDistance : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Line length: ${pixelDistance.toStringAsFixed(1)} image pixels',
          style: TextStyle(
            fontSize: 11,
            color: Colors.green[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Represents: ${realDistance.toStringAsFixed(1)} ${_selectedUnit.symbol}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.green[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Scale: ${pixelsPerUnit.toStringAsFixed(2)} pixels/${_selectedUnit.symbol}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.green[600],
          ),
        ),
      ],
    );
  }

  void _completeCalibration() {
    if (_startPointNormalized == null || _endPointNormalized == null || _distanceController.text.isEmpty) {
      return;
    }

    final double distance = double.tryParse(_distanceController.text) ?? 0;
    if (distance <= 0) {
      return;
    }

    try {
      final Offset startImagePixels = _normalizedToImagePixels(_startPointNormalized!);
      final Offset endImagePixels = _normalizedToImagePixels(_endPointNormalized!);

      final Offset diff = endImagePixels - startImagePixels;
      final double pixelDist = diff.distance;

      if (pixelDist.isNaN || pixelDist.isInfinite || pixelDist <= 0) {
        return;
      }

      final CalibrationData calibrationData = CalibrationData(
        startPoint: startImagePixels, // Use actual image pixel coordinates
        endPoint: endImagePixels, // Use actual image pixel coordinates
        realWorldDistance: distance,
        unit: _selectedUnit,
        imageSize: Size(
          widget.floorPlanImage.width.toDouble(),
          widget.floorPlanImage.height.toDouble(),
        ),
      );

      widget.onCalibrationComplete(calibrationData);
    } catch (e, stackTrace) {
      debugPrint('Error completing calibration: $e\n$stackTrace');
    }
  }

  void _clearCalibration() {
    setState(() {
      _startPointNormalized = null;
      _endPointNormalized = null;
      _startPointDisplay = null;
      _endPointDisplay = null;
      _isDrawing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check for invalid image
    if (widget.floorPlanImage.width <= 0 || widget.floorPlanImage.height <= 0) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                color: Colors.grey[600],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Invalid image',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Image dimensions: ${widget.floorPlanImage.width}x${widget.floorPlanImage.height}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Row(
        children: <Widget>[
          // Left side - Image editor
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[200],
              child: Column(
                children: <Widget>[
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.straighten, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Scale Floor Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Image area
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.precise,
                          onHover: _onHover,
                          child: GestureDetector(
                            onTapDown: _onTapDown,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: CustomPaint(
                              painter: FloorPlanCalibrationPainter(
                                image: widget.floorPlanImage,
                                startPoint: _startPointDisplay,
                                endPoint: _endPointDisplay,
                                distanceText: _distanceController.text,
                                unit: _selectedUnit,
                                onImageRectChanged: (ui.Rect rect) {
                                  _currentImageRect = rect;
                                  // Update display points when image rect changes
                                  if (_startPointNormalized != null) {
                                    _startPointDisplay = _normalizedToScreen(_startPointNormalized!);
                                  }
                                  if (_endPointNormalized != null) {
                                    _endPointDisplay = _normalizedToScreen(_endPointNormalized!);
                                  }
                                },
                              ),
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: double.infinity,
                                  maxHeight: double.infinity,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            width: 280,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Instructions
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Instructions:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '1. Draw a line of known distance\n2. Enter the real-world distance\n3. Select the measurement unit\n4. The scale will be calculated automatically',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Distance input
                          Text(
                            'Distance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _distanceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Enter known distance',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Unit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<MeasurementUnit>(
                            value: _selectedUnit,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items:
                                MeasurementUnit.values.map((MeasurementUnit unit) {
                                  return DropdownMenuItem<MeasurementUnit>(
                                    value: unit,
                                    child: Text(unit.displayName),
                                  );
                                }).toList(),
                            onChanged: (MeasurementUnit? value) {
                              setState(() {
                                _selectedUnit = value!;
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // if (_startPointNormalized != null && _endPointNormalized != null) ...<Widget>[
                          //   Container(
                          //     padding: const EdgeInsets.all(12),
                          //     decoration: BoxDecoration(
                          //       color: Colors.green[50],
                          //       borderRadius: BorderRadius.circular(8),
                          //       border: Border.all(color: Colors.green[200]!),
                          //     ),
                          //     child: Column(
                          //       crossAxisAlignment: CrossAxisAlignment.start,
                          //       children: <Widget>[
                          //         Row(
                          //           children: <Widget>[
                          //             Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                          //             const SizedBox(width: 8),
                          //             Text(
                          //               'Calibration Line Drawn',
                          //               style: TextStyle(
                          //                 fontSize: 12,
                          //                 fontWeight: FontWeight.w500,
                          //                 color: Colors.green[700],
                          //               ),
                          //             ),
                          //           ],
                          //         ),
                          //         const SizedBox(height: 8),
                          //         _buildCalibrationInfo(),
                          //       ],
                          //     ),
                          //   ),
                          // ],
                          // const SizedBox(height: 20),
                          if (_startPointNormalized != null || _endPointNormalized != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: OutlinedButton(
                                onPressed: _clearCalibration,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey[400]!),
                                  foregroundColor: Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Clear Line',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed:
                              _startPointNormalized != null && _endPointNormalized != null && _distanceController.text.isNotEmpty ? _completeCalibration : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[400]!),
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloorPlanCalibrationPainter extends CustomPainter {
  final ui.Image image;
  final Offset? startPoint;
  final Offset? endPoint;
  final String distanceText;
  final MeasurementUnit unit;
  final Function(Rect)? onImageRectChanged;

  FloorPlanCalibrationPainter({
    required this.image,
    this.startPoint,
    this.endPoint,
    this.distanceText = '',
    required this.unit,
    this.onImageRectChanged,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (image.width <= 0 || image.height <= 0) return;

    final double imageAspectRatio = image.width / image.height;
    final double canvasAspectRatio = size.width / size.height;

    if (imageAspectRatio.isNaN || imageAspectRatio.isInfinite || imageAspectRatio <= 0) return;
    if (canvasAspectRatio.isNaN || canvasAspectRatio.isInfinite || canvasAspectRatio <= 0) return;

    late Size scaledSize;
    late Offset offset;

    if (imageAspectRatio > canvasAspectRatio) {
      scaledSize = Size(size.width, size.width / imageAspectRatio);
      offset = Offset(0, (size.height - scaledSize.height) / 2);
    } else {
      scaledSize = Size(size.height * imageAspectRatio, size.height);
      offset = Offset((size.width - scaledSize.width) / 2, 0);
    }

    if (scaledSize.width <= 0 ||
        scaledSize.height <= 0 ||
        scaledSize.width.isNaN ||
        scaledSize.height.isNaN ||
        scaledSize.width.isInfinite ||
        scaledSize.height.isInfinite)
      return;

    if (offset.dx.isNaN || offset.dy.isNaN || offset.dx.isInfinite || offset.dy.isInfinite) return;

    final Rect imageRect = offset & scaledSize;

    if (onImageRectChanged != null) {
      onImageRectChanged!(imageRect);
    }

    try {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        imageRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } catch (e) {
      return;
    }

    if (startPoint != null && endPoint != null) {
      if (startPoint!.dx.isNaN ||
          startPoint!.dy.isNaN ||
          startPoint!.dx.isInfinite ||
          startPoint!.dy.isInfinite ||
          endPoint!.dx.isNaN ||
          endPoint!.dy.isNaN ||
          endPoint!.dx.isInfinite ||
          endPoint!.dy.isInfinite)
        return;

      try {
        final Paint linePaint =
            Paint()
              ..color = Colors.red
              ..strokeWidth = 5
              ..style = PaintingStyle.stroke;

        final Paint pointPaint =
            Paint()
              ..color = Colors.red
              ..style = PaintingStyle.fill;

        canvas.drawLine(startPoint!, endPoint!, linePaint);

        // Draw perpendicular lines at start and end points
        final Offset lineVector = endPoint! - startPoint!;
        final double lineLength = lineVector.distance;
        if (lineLength > 0) {
          // Normalize the line vector
          final Offset normalizedLine = lineVector / lineLength;
          // Create perpendicular vector (rotate 90 degrees)
          final Offset perpendicular = Offset(-normalizedLine.dy, normalizedLine.dx);

          const double edgeLineLength = 10.0;
          final Offset edgeOffset = perpendicular * edgeLineLength;

          final Paint edgePaint =
              Paint()
                ..color = Colors.red
                ..strokeWidth = 5
                ..style = PaintingStyle.stroke;

          // Draw edge lines at start point
          canvas.drawLine(
            startPoint! - edgeOffset,
            startPoint! + edgeOffset,
            edgePaint,
          );

          // Draw edge lines at end point
          canvas.drawLine(
            endPoint! - edgeOffset,
            endPoint! + edgeOffset,
            edgePaint,
          );
        }

        final Offset diff = endPoint! - startPoint!;
        final double pixelDistance = diff.distance;

        if (pixelDistance > 0 && !pixelDistance.isNaN && !pixelDistance.isInfinite) {
          final Offset midPoint = Offset(
            (startPoint!.dx + endPoint!.dx) / 2,
            (startPoint!.dy + endPoint!.dy) / 2,
          );

          if (midPoint.dx.isNaN || midPoint.dy.isNaN || midPoint.dx.isInfinite || midPoint.dy.isInfinite) return;

          final String labelText = distanceText.isNotEmpty ? '$distanceText ${unit.symbol}' : '1 ${unit.symbol}';

          final TextPainter textPainter = TextPainter(
            text: TextSpan(
              text: labelText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
          );

          textPainter.layout();

          final double labelOffsetY = -25;
          final Offset labelPosition = Offset(
            midPoint.dx - textPainter.width / 2,
            midPoint.dy + labelOffsetY - textPainter.height / 2,
          );

          if (labelPosition.dx.isNaN || labelPosition.dy.isNaN || labelPosition.dx.isInfinite || labelPosition.dy.isInfinite) return;

          final Paint bgPaint =
              Paint()
                ..color = Colors.black.withOpacity(0.8)
                ..style = PaintingStyle.fill;

          const double padding = 6.0;
          final RRect labelBg = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              labelPosition.dx - padding,
              labelPosition.dy - padding,
              textPainter.width + (padding * 2),
              textPainter.height + (padding * 2),
            ),
            const Radius.circular(4),
          );

          canvas.drawRRect(labelBg, bgPaint);
          textPainter.paint(canvas, labelPosition);
        }
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CalibrationData {
  final Offset startPoint;
  final Offset endPoint;
  final double realWorldDistance;
  final MeasurementUnit unit;
  final Size imageSize;

  CalibrationData({
    required this.startPoint,
    required this.endPoint,
    required this.realWorldDistance,
    required this.unit,
    required this.imageSize,
  }) {
    if (startPoint.dx.isNaN || startPoint.dy.isNaN) {
      throw ArgumentError('Start point contains NaN values: $startPoint');
    }
    if (endPoint.dx.isNaN || endPoint.dy.isNaN) {
      throw ArgumentError('End point contains NaN values: $endPoint');
    }
    if (realWorldDistance.isNaN || realWorldDistance <= 0) {
      throw ArgumentError('Invalid real world distance: $realWorldDistance');
    }
    if (imageSize.width.isNaN || imageSize.height.isNaN || imageSize.width <= 0 || imageSize.height <= 0) {
      throw ArgumentError('Invalid image size: $imageSize');
    }
  }

  double get pixelDistance {
    try {
      final Offset diff = endPoint - startPoint;
      final double distance = diff.distance;
      if (distance.isNaN || distance.isInfinite) return 0.0;
      return distance;
    } catch (e) {
      return 0.0;
    }
  }

  double get pixelsPerUnit {
    try {
      final double distance = pixelDistance;
      if (distance <= 0 || realWorldDistance <= 0) return 0.0;
      final double ratio = distance / realWorldDistance;
      return ratio.isNaN || ratio.isInfinite ? 0.0 : ratio;
    } catch (e) {
      return 0.0;
    }
  }

  double get unitsPerPixel {
    try {
      final double distance = pixelDistance;
      if (distance <= 0 || realWorldDistance <= 0) return 0.0;
      final double ratio = realWorldDistance / distance;
      return ratio.isNaN || ratio.isInfinite ? 0.0 : ratio;
    } catch (e) {
      return 0.0;
    }
  }

  double pixelsToUnits(double pixels) {
    final double ratio = unitsPerPixel;
    return ratio > 0 ? pixels * ratio : 0.0;
  }

  double unitsToPixels(double units) {
    final double ratio = pixelsPerUnit;
    return ratio > 0 ? units * ratio : 0.0;
  }

  @override
  String toString() {
    try {
      final double distance = pixelDistance;
      final String distanceStr = distance.isNaN || distance.isInfinite ? '0.0' : distance.toStringAsFixed(1);
      return 'CalibrationData(${realWorldDistance} ${unit.symbol} = ${distanceStr}px)';
    } catch (e) {
      return 'CalibrationData(${realWorldDistance} ${unit.symbol} = error calculating distance)';
    }
  }
}

enum MeasurementUnit {
  meters('m', 'Meters'),
  feet('ft', 'Feet'),
  centimeters('cm', 'Centimeters'),
  inches('in', 'Inches');

  const MeasurementUnit(this.symbol, this.displayName);

  final String symbol;
  final String displayName;
}
