import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../di/service_locator.dart';

class FloorPlanCalibrationDialog extends StatelessWidget {
  final ui.Image floorPlanImage;
  final Function(CalibrationData) onCalibrationComplete;
  final VoidCallback? onCancel;
  final String title;

  const FloorPlanCalibrationDialog({
    super.key,
    required this.floorPlanImage,
    required this.onCalibrationComplete,
    this.onCancel,
    this.title = 'Floor plan 1',
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "floor_plan_calibration_dialog"),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, "floor_plan_calibrator_title_bar"),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: <Widget>[
                    FusionAppText(
                      text: title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.closeX),
                      child: IconButton(
                        tooltip: 'Close',
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        splashRadius: 18,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),

                Flexible(
                  child: SemanticHelper.container(
                    testId: SemanticHelper.createTestId(SemanticTypes.container, "floor_plan_calibrator"),
                    child: FloorPlanCalibrator(
                      floorPlanImage: floorPlanImage,
                      onCalibrationComplete: onCalibrationComplete,
                      onCancel: onCancel,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ToolMode { measure, crop, rotate, skew }

class FloorPlanCalibrator extends StatefulWidget {
  final ui.Image floorPlanImage;
  final Function(CalibrationData) onCalibrationComplete;
  final VoidCallback? onCancel;

  const FloorPlanCalibrator({
    super.key,
    required this.floorPlanImage,
    required this.onCalibrationComplete,
    this.onCancel,
  });

  @override
  State<FloorPlanCalibrator> createState() => _FloorPlanCalibratorState();
}

class _FloorPlanCalibratorState extends State<FloorPlanCalibrator> {
  // --- working image state (updated when crop/transforms are applied) ---
  ui.Image? _workingImage;

  // --- rotation state ---
  double _rotationAngle = 0.0; // in radians
  bool _isRotating = false;
  double _rotationStartAngle = 0.0;
  double _initialRotation = 0.0;
  _RotationHandle _activeRotationHandle = _RotationHandle.none;
  static const double _quickRotateAngle = 90.0 * math.pi / 180; // 90 degrees in radians
  // --- skew/transform state (4-point free transform with corner offsets) ---
  // Corner offsets are normalized relative to image dimensions (-1.0 to 1.0)
  Offset _cornerOffsetTL = Offset.zero; // topLeft offset
  Offset _cornerOffsetTR = Offset.zero; // topRight offset
  Offset _cornerOffsetBL = Offset.zero; // bottomLeft offset
  Offset _cornerOffsetBR = Offset.zero; // bottomRight offset
  bool _isSkewing = false;
  _SkewHandle _activeSkewHandle = _SkewHandle.none;
  final Offset _skewStartPosition = Offset.zero;
  // Store starting offsets for all corners (needed for pivot-based skew)
  final Offset _cornerStartTL = Offset.zero;
  final Offset _cornerStartTR = Offset.zero;
  final Offset _cornerStartBL = Offset.zero;
  final Offset _cornerStartBR = Offset.zero;
  bool _hasPendingSkew = false; // true when skew is modified but not yet applied
  // --- zoom/pan state ---
  double _zoomScale = 1.0;
  Offset _panOffset = Offset.zero;
  static const double minZoom = 0.1, maxZoom = 10.0;
  // --- measurement state ---
  Offset? _startPointNormalized;
  Offset? _endPointNormalized;
  Offset? _startPointDisplay;
  Offset? _endPointDisplay;
  bool _isDrawing = false;
  Offset _lastSkewPosition = Offset.zero;

  // --- crop state (normalized to the displayed image rect 0..1) ---
  Rect _cropRectN = const Rect.fromLTWH(0, 0, 1, 1);
  _CropHandle _activeHandle = _CropHandle.none;
  bool _hasPendingCrop = false; // true when crop rect is modified but not yet applied

  // Helper to get the current display image
  ui.Image get _currentImage => _workingImage ?? widget.floorPlanImage;

  // --- zoom/pan state ---
  Offset _panZoomStartPan = Offset.zero;
  Offset _panZoomStartFocal = Offset.zero;
  double _panZoomStartScale = 1.0;
  bool _isMiddleMousePanning = false;
  Offset _middleMousePanStart = Offset.zero;
  Offset _middleMousePanOffset = Offset.zero;

  // --- UI/controls ---
  final TextEditingController _distanceController = TextEditingController(
    text: '5.00',
  );
  MeasurementUnit _selectedUnit = MeasurementUnit.feet;
  _ToolMode _mode = _ToolMode.measure;

  // current image rect on screen (used for conversions)
  Rect? _imageRect;

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  // ---------- coords helpers ----------
  Offset? _screenToNormalized(Offset p) {
    final r = _imageRect;
    if (r == null) return null;
    // Adjust for pan/zoom
    final local = (p - _panOffset) / _zoomScale;
    final x = ((local.dx - r.left) / r.width).clamp(0.0, 1.0);
    final y = ((local.dy - r.top) / r.height).clamp(0.0, 1.0);
    return Offset(x, y);
  }

  Offset _screenToCanvas(Offset p) => (p - _panOffset) / _zoomScale;

  Offset _canvasToScreen(Offset p) => p * _zoomScale + _panOffset;

  Offset? _normalizedToCanvas(Offset n) {
    final r = _imageRect;
    if (r == null) return null;
    return Offset(r.left + n.dx * r.width, r.top + n.dy * r.height);
  }

  // Handle mouse wheel/trackpad zoom
  void _handleScrollWheelZoom(PointerSignalEvent p) {
    if (p is PointerScrollEvent) {
      final double d = p.scrollDelta.dy;
      final Offset f = p.localPosition;
      setState(() {
        final double prop = _zoomScale * (1 - d * 0.001);
        final double c = prop.clamp(minZoom, maxZoom);
        final double zf = c / _zoomScale;
        _panOffset = (_panOffset - f) * zf + f;
        _zoomScale = c;
      });
    }
  }

  Offset _normalizedToImagePx(Offset n) => Offset(n.dx * _currentImage.width, n.dy * _currentImage.height);

  // ---------- measure interactions ----------
  void _onMeasureTapDown(TapDownDetails d) {
    final n = _screenToNormalized(d.localPosition);
    if (n == null) return;
    final local = _screenToCanvas(d.localPosition);

    if (_startPointNormalized == null || !_isDrawing) {
      setState(() {
        _startPointNormalized = n;
        _startPointDisplay = local;
        _endPointNormalized = null;
        _endPointDisplay = null;
        _isDrawing = true;
      });
    } else {
      setState(() {
        _endPointNormalized = n;
        _endPointDisplay = local;
        _isDrawing = false;
      });
      fusionLibLocator<GuideShowCaseController>().completeStep(
        GuideShowCaseSteps.showFloorPickCalibration,
      );
    }
  }

  void _onMeasurePanUpdate(DragUpdateDetails d) {
    if (!_isDrawing || _startPointNormalized == null) return;
    final n = _screenToNormalized(d.localPosition);
    if (n == null) return;
    setState(() {
      _endPointNormalized = n;
      _endPointDisplay = _screenToCanvas(d.localPosition);
    });
  }

  void _onMeasureHover(PointerHoverEvent e) {
    if (!_isDrawing || _startPointNormalized == null) return;
    final n = _screenToNormalized(e.localPosition);
    if (n == null) return;
    setState(() {
      _endPointNormalized = n;
      _endPointDisplay = _screenToCanvas(e.localPosition);
    });
  }

  // ---------- crop interactions ----------
  void _onCropPanStart(DragStartDetails d) {
    final r = _imageRect;
    if (r == null) return;

    // hit-test handles in screen space
    final handles = _handlesInScreen(r, _cropRectN);
    const hitSize = 20.0; // Increased hit size for better touch detection
    final p = d.localPosition;

    _activeHandle = _CropHandle.none;

    // Check each handle for hits, including those that may extend beyond image bounds
    for (final entry in handles.entries) {
      final handlePos = entry.value;
      final distance = (handlePos - p).distance;

      // Check if the touch is within the hit area of this handle
      if (distance <= hitSize) {
        _activeHandle = entry.key;
        break;
      }
    }
  }

  void _onCropPanUpdate(DragUpdateDetails d) {
    if (_activeHandle == _CropHandle.none) return;

    final r = _imageRect;
    if (r == null) return;

    // Allow pan updates even if they're outside the image bounds
    // but clamp the resulting crop rectangle to valid ranges
    final screenPos = d.localPosition;

    final local = _screenToCanvas(screenPos);

    // Apply inverse rotation to get coordinates in the unrotated image space
    final imgCx = r.center.dx;
    final imgCy = r.center.dy;
    final cos = math.cos(-_rotationAngle); // Inverse rotation
    final sin = math.sin(-_rotationAngle);
    final dx = local.dx - imgCx;
    final dy = local.dy - imgCy;
    final unrotatedLocal = Offset(
      imgCx + dx * cos - dy * sin,
      imgCy + dx * sin + dy * cos,
    );

    // Convert screen position to normalized coordinates relative to image
    final normalizedX = ((unrotatedLocal.dx - r.left) / r.width).clamp(0.0, 1.0);
    final normalizedY = ((unrotatedLocal.dy - r.top) / r.height).clamp(0.0, 1.0);
    final n = Offset(normalizedX, normalizedY);

    Rect newN = _cropRectN;
    // min size in normalized units (~12px on a medium canvas)
    const double minW = 12 / 1200;
    const double minH = 12 / 800;

    switch (_activeHandle) {
      case _CropHandle.topLeft:
        newN = Rect.fromLTRB(
          n.dx.clamp(0.0, newN.right - minW),
          n.dy.clamp(0.0, newN.bottom - minH),
          newN.right,
          newN.bottom,
        );
        break;
      case _CropHandle.top:
        newN = Rect.fromLTRB(
          newN.left,
          n.dy.clamp(0.0, newN.bottom - minH),
          newN.right,
          newN.bottom,
        );
        break;
      case _CropHandle.topRight:
        newN = Rect.fromLTRB(
          newN.left,
          n.dy.clamp(0.0, newN.bottom - minH),
          n.dx.clamp(newN.left + minW, 1.0),
          newN.bottom,
        );
        break;
      case _CropHandle.right:
        newN = Rect.fromLTRB(
          newN.left,
          newN.top,
          n.dx.clamp(newN.left + minW, 1.0),
          newN.bottom,
        );
        break;
      case _CropHandle.bottomRight:
        newN = Rect.fromLTRB(
          newN.left,
          newN.top,
          n.dx.clamp(newN.left + minW, 1.0),
          n.dy.clamp(newN.top + minH, 1.0),
        );
        break;
      case _CropHandle.bottom:
        newN = Rect.fromLTRB(
          newN.left,
          newN.top,
          newN.right,
          n.dy.clamp(newN.top + minH, 1.0),
        );
        break;
      case _CropHandle.bottomLeft:
        newN = Rect.fromLTRB(
          n.dx.clamp(0.0, newN.right - minW),
          newN.top,
          newN.right,
          n.dy.clamp(newN.top + minH, 1.0),
        );
        break;
      case _CropHandle.left:
        newN = Rect.fromLTRB(
          n.dx.clamp(0.0, newN.right - minW),
          newN.top,
          newN.right,
          newN.bottom,
        );
        break;
      case _CropHandle.none:
        break;
    }

    setState(() {
      _cropRectN = newN;
      // Mark as pending crop if the crop rect is not full image
      _hasPendingCrop = newN != const Rect.fromLTWH(0, 0, 1, 1);
    });
  }

  void _onCropPanEnd(DragEndDetails d) {
    _activeHandle = _CropHandle.none;
  }

  // ---------- rotation interactions ----------
  Map<_RotationHandle, Offset> _rotationHandlesInScreen(Rect imageRect) {
    // Apply rotation to get the actual corner positions
    final center = imageRect.center;
    final cos = math.cos(_rotationAngle);
    final sin = math.sin(_rotationAngle);

    Offset rotatePoint(Offset p) {
      final dx = p.dx - center.dx;
      final dy = p.dy - center.dy;
      return Offset(
        center.dx + dx * cos - dy * sin,
        center.dy + dx * sin + dy * cos,
      );
    }

    return <_RotationHandle, Offset>{
      _RotationHandle.topLeft: _canvasToScreen(rotatePoint(imageRect.topLeft)),
      _RotationHandle.topRight: _canvasToScreen(rotatePoint(imageRect.topRight)),
      _RotationHandle.bottomRight: _canvasToScreen(rotatePoint(imageRect.bottomRight)),
      _RotationHandle.bottomLeft: _canvasToScreen(rotatePoint(imageRect.bottomLeft)),
    };
  }

  void _onRotatePanStart(DragStartDetails d) {
    final r = _imageRect;
    if (r == null) return;

    final handles = _rotationHandlesInScreen(r);
    const hitSize = 20.0;
    final p = d.localPosition;

    _activeRotationHandle = _RotationHandle.none;

    for (final entry in handles.entries) {
      final handlePos = entry.value;
      final distance = (handlePos - p).distance;
      if (distance <= hitSize) {
        _activeRotationHandle = entry.key;
        break;
      }
    }

    if (_activeRotationHandle != _RotationHandle.none) {
      // Calculate the center of the image in screen space
      final center = _canvasToScreen(r.center);
      // Calculate the initial angle from center to pointer
      _rotationStartAngle = math.atan2(
        p.dy - center.dy,
        p.dx - center.dx,
      );
      _initialRotation = _rotationAngle;
      setState(() => _isRotating = true);
    }
  }

  void _onRotatePanUpdate(DragUpdateDetails d) {
    if (_activeRotationHandle == _RotationHandle.none || !_isRotating) return;

    final r = _imageRect;
    if (r == null) return;

    final p = d.localPosition;
    final center = _canvasToScreen(r.center);

    // Calculate current angle from center to pointer
    final currentAngle = math.atan2(
      p.dy - center.dy,
      p.dx - center.dx,
    );

    // Calculate the rotation delta and apply to initial rotation
    final deltaAngle = currentAngle - _rotationStartAngle;
    setState(() {
      _rotationAngle = _initialRotation + deltaAngle;
    });
  }

  void _onRotatePanEnd(DragEndDetails d) {
    _activeRotationHandle = _RotationHandle.none;
    setState(() => _isRotating = false);
  }

  void _rotateLeft() {
    setState(() {
      _rotationAngle -= _quickRotateAngle;
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationAngle += _quickRotateAngle;
    });
  }

  // ---------- 4-point free transform interaction ----------

  // Get the actual corner positions with offsets applied (in canvas coordinates)
  Map<_SkewHandle, Offset> _getTransformCorners(Rect imageRect) {
    final w = imageRect.width;
    final h = imageRect.height;

    // Base corners + their offsets (offsets are normalized, multiply by dimensions)
    final topLeft = imageRect.topLeft + Offset(_cornerOffsetTL.dx * w, _cornerOffsetTL.dy * h);
    final topRight = imageRect.topRight + Offset(_cornerOffsetTR.dx * w, _cornerOffsetTR.dy * h);
    final bottomLeft = imageRect.bottomLeft + Offset(_cornerOffsetBL.dx * w, _cornerOffsetBL.dy * h);
    final bottomRight = imageRect.bottomRight + Offset(_cornerOffsetBR.dx * w, _cornerOffsetBR.dy * h);

    // Edge midpoints (calculated from actual corner positions)
    final topCenter = Offset((topLeft.dx + topRight.dx) / 2, (topLeft.dy + topRight.dy) / 2);
    final bottomCenter = Offset((bottomLeft.dx + bottomRight.dx) / 2, (bottomLeft.dy + bottomRight.dy) / 2);
    final leftCenter = Offset((topLeft.dx + bottomLeft.dx) / 2, (topLeft.dy + bottomLeft.dy) / 2);
    final rightCenter = Offset((topRight.dx + bottomRight.dx) / 2, (topRight.dy + bottomRight.dy) / 2);

    return {
      _SkewHandle.topLeft: topLeft,
      _SkewHandle.topRight: topRight,
      _SkewHandle.bottomLeft: bottomLeft,
      _SkewHandle.bottomRight: bottomRight,
      _SkewHandle.topCenter: topCenter,
      _SkewHandle.bottomCenter: bottomCenter,
      _SkewHandle.leftCenter: leftCenter,
      _SkewHandle.rightCenter: rightCenter,
    };
  }

  Map<_SkewHandle, Offset> _skewHandlesInScreen(Rect imageRect) {
    final cx = imageRect.center.dx;
    final cy = imageRect.center.dy;

    // Get corners with offsets applied
    final corners = _getTransformCorners(imageRect);

    // Apply rotation transform to handle positions
    final cos = math.cos(_rotationAngle);
    final sin = math.sin(_rotationAngle);

    Offset rotatePoint(Offset p) {
      final dx = p.dx - cx;
      final dy = p.dy - cy;
      return Offset(
        cx + dx * cos - dy * sin,
        cy + dx * sin + dy * cos,
      );
    }

    // Transform all corners: rotate, then convert to screen coords
    // Flip is now applied immediately to working image, so no flip transform needed here
    return corners.map((key, value) {
      final point = rotatePoint(value);
      // Convert to screen coordinates
      return MapEntry(
        key,
        Offset(
          point.dx * _zoomScale + _panOffset.dx,
          point.dy * _zoomScale + _panOffset.dy,
        ),
      );
    });
  }

  _SkewHandle _hitTestSkewHandle(Offset p) {
    final r = _imageRect;
    if (r == null) return _SkewHandle.none;

    final handles = _skewHandlesInScreen(r);
    const double tolerance = 20;

    // Check corners first (higher priority)
    for (final corner in [_SkewHandle.topLeft, _SkewHandle.topRight, _SkewHandle.bottomLeft, _SkewHandle.bottomRight]) {
      if ((handles[corner]! - p).distance <= tolerance) {
        return corner;
      }
    }
    // Then check edge centers
    for (final edge in [_SkewHandle.topCenter, _SkewHandle.bottomCenter, _SkewHandle.leftCenter, _SkewHandle.rightCenter]) {
      if ((handles[edge]! - p).distance <= tolerance) {
        return edge;
      }
    }
    return _SkewHandle.none;
  }

  void _onSkewPanStart(DragStartDetails d) {
    final handle = _hitTestSkewHandle(d.localPosition);

    if (handle != _SkewHandle.none) {
      setState(() {
        _activeSkewHandle = handle;
        _isSkewing = true;
        _lastSkewPosition = d.localPosition;
      });
    }
  }

  void _onSkewPanUpdate(DragUpdateDetails d) {
    if (_activeSkewHandle == _SkewHandle.none || !_isSkewing) return;

    final r = _imageRect;
    if (r == null) return;

    // incremental delta
    final screenDelta = d.localPosition - _lastSkewPosition;
    _lastSkewPosition = d.localPosition;

    // convert to local image space (respect rotation)
    final cos = math.cos(-_rotationAngle);
    final sin = math.sin(-_rotationAngle);

    final localDX = screenDelta.dx * cos - screenDelta.dy * sin;
    final localDY = screenDelta.dx * sin + screenDelta.dy * cos;

    final normalizedDX = localDX / (r.width * _zoomScale);
    final normalizedDY = localDY / (r.height * _zoomScale);

    setState(() {
      switch (_activeSkewHandle) {
        /// CORNERS — free movement
        case _SkewHandle.topLeft:
          _cornerOffsetTL += Offset(normalizedDX, normalizedDY);
          break;

        case _SkewHandle.topRight:
          _cornerOffsetTR += Offset(normalizedDX, normalizedDY);
          break;

        case _SkewHandle.bottomLeft:
          _cornerOffsetBL += Offset(normalizedDX, normalizedDY);
          break;

        case _SkewHandle.bottomRight:
          _cornerOffsetBR += Offset(normalizedDX, normalizedDY);
          break;

        /// EDGE HANDLES — constrained movement

        // top edge → horizontal only
        case _SkewHandle.topCenter:
          _cornerOffsetTL += Offset(normalizedDX, 0);
          _cornerOffsetTR += Offset(normalizedDX, 0);
          break;

        // bottom edge → horizontal only
        case _SkewHandle.bottomCenter:
          _cornerOffsetBL += Offset(normalizedDX, 0);
          _cornerOffsetBR += Offset(normalizedDX, 0);
          break;

        // left edge → vertical only
        case _SkewHandle.leftCenter:
          _cornerOffsetTL += Offset(0, normalizedDY);
          _cornerOffsetBL += Offset(0, normalizedDY);
          break;

        // right edge → vertical only
        case _SkewHandle.rightCenter:
          _cornerOffsetTR += Offset(0, normalizedDY);
          _cornerOffsetBR += Offset(0, normalizedDY);
          break;

        case _SkewHandle.none:
          break;
      }

      _hasPendingSkew = _cornerOffsetTL != Offset.zero || _cornerOffsetTR != Offset.zero || _cornerOffsetBL != Offset.zero || _cornerOffsetBR != Offset.zero;
    });
  }

  void _onSkewPanEnd(DragEndDetails d) {
    _activeSkewHandle = _SkewHandle.none;
    setState(() => _isSkewing = false);
  }

  void _resetSkew() {
    setState(() {
      _cornerOffsetTL = Offset.zero;
      _cornerOffsetTR = Offset.zero;
      _cornerOffsetBL = Offset.zero;
      _cornerOffsetBR = Offset.zero;
      _hasPendingSkew = false;
    });
  }

  void _cancelSkew() {
    _resetSkew();
  }

  Future<void> _applySkew() async {
    if (!_hasPendingSkew) return;

    final sourceImage = _currentImage;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final fullWidth = sourceImage.width.toDouble();
      final fullHeight = sourceImage.height.toDouble();

      // Calculate transformed corner positions
      final tl = Offset(
        _cornerOffsetTL.dx * fullWidth,
        _cornerOffsetTL.dy * fullHeight,
      );
      final tr = Offset(
        fullWidth + _cornerOffsetTR.dx * fullWidth,
        _cornerOffsetTR.dy * fullHeight,
      );
      final br = Offset(
        fullWidth + _cornerOffsetBR.dx * fullWidth,
        fullHeight + _cornerOffsetBR.dy * fullHeight,
      );
      final bl = Offset(
        _cornerOffsetBL.dx * fullWidth,
        fullHeight + _cornerOffsetBL.dy * fullHeight,
      );

      // Calculate bounding box of transformed corners
      final minX = [tl.dx, tr.dx, br.dx, bl.dx].reduce((a, b) => a < b ? a : b);
      final maxX = [tl.dx, tr.dx, br.dx, bl.dx].reduce((a, b) => a > b ? a : b);
      final minY = [tl.dy, tr.dy, br.dy, bl.dy].reduce((a, b) => a < b ? a : b);
      final maxY = [tl.dy, tr.dy, br.dy, bl.dy].reduce((a, b) => a > b ? a : b);

      final newWidth = maxX - minX;
      final newHeight = maxY - minY;

      // Translate corners to positive coordinates
      final tlAdjusted = Offset(tl.dx - minX, tl.dy - minY);
      final trAdjusted = Offset(tr.dx - minX, tr.dy - minY);
      final brAdjusted = Offset(br.dx - minX, br.dy - minY);
      final blAdjusted = Offset(bl.dx - minX, bl.dy - minY);

      _drawTexturedQuad(
        canvas,
        image: sourceImage,
        dstTL: tlAdjusted,
        dstTR: trAdjusted,
        dstBL: blAdjusted,
        dstBR: brAdjusted,
      );

      final picture = recorder.endRecording();
      final resultImage = await picture.toImage(newWidth.round(), newHeight.round());

      setState(() {
        _workingImage = resultImage;
        // Reset skew offsets since they've been applied
        _cornerOffsetTL = Offset.zero;
        _cornerOffsetTR = Offset.zero;
        _cornerOffsetBL = Offset.zero;
        _cornerOffsetBR = Offset.zero;
        _hasPendingSkew = false;
      });
    } catch (e) {
      // If skew fails, just reset the pending state
      setState(() => _hasPendingSkew = false);
    }
  }

  Map<_CropHandle, Offset> _handlesInScreen(Rect imageRect, Rect cropN) {
    final crop = Rect.fromLTRB(
      imageRect.left + cropN.left * imageRect.width,
      imageRect.top + cropN.top * imageRect.height,
      imageRect.left + cropN.right * imageRect.width,
      imageRect.top + cropN.bottom * imageRect.height,
    );

    final centerX = (crop.left + crop.right) / 2;
    final centerY = (crop.top + crop.bottom) / 2;

    // Apply rotation to handle positions
    final imgCx = imageRect.center.dx;
    final imgCy = imageRect.center.dy;
    final cos = math.cos(_rotationAngle);
    final sin = math.sin(_rotationAngle);

    Offset rotatePoint(Offset p) {
      final dx = p.dx - imgCx;
      final dy = p.dy - imgCy;
      return Offset(
        imgCx + dx * cos - dy * sin,
        imgCy + dx * sin + dy * cos,
      );
    }

    return <_CropHandle, Offset>{
      _CropHandle.topLeft: _canvasToScreen(rotatePoint(Offset(crop.left, crop.top))),
      _CropHandle.top: _canvasToScreen(rotatePoint(Offset(centerX, crop.top))),
      _CropHandle.topRight: _canvasToScreen(rotatePoint(Offset(crop.right, crop.top))),
      _CropHandle.right: _canvasToScreen(rotatePoint(Offset(crop.right, centerY))),
      _CropHandle.bottomRight: _canvasToScreen(rotatePoint(Offset(crop.right, crop.bottom))),
      _CropHandle.bottom: _canvasToScreen(rotatePoint(Offset(centerX, crop.bottom))),
      _CropHandle.bottomLeft: _canvasToScreen(rotatePoint(Offset(crop.left, crop.bottom))),
      _CropHandle.left: _canvasToScreen(rotatePoint(Offset(crop.left, centerY))),
    };
  }

  // ---------- actions ----------
  void _clearMeasurement() {
    setState(() {
      _startPointNormalized = null;
      _endPointNormalized = null;
      _startPointDisplay = null;
      _endPointDisplay = null;
      _isDrawing = false;
    });
  }

  void _resetCrop() {
    setState(() {
      _cropRectN = const Rect.fromLTWH(0, 0, 1, 1);
      _hasPendingCrop = false;
    });
  }

  void _cancelCrop() {
    // Reset crop rect to full image
    setState(() {
      _cropRectN = const Rect.fromLTWH(0, 0, 1, 1);
      _hasPendingCrop = false;
    });
  }

  Future<void> _applyCrop() async {
    if (!_hasPendingCrop) return;

    final sourceImage = _currentImage;

    try {
      ui.Image resultImage = sourceImage;

      // Step 1: Apply crop FIRST to the source image (in unrotated space)
      // Because _cropRectN coordinates are in unrotated image space
      final cropRect = Rect.fromLTRB(
        (_cropRectN.left * sourceImage.width).round().toDouble(),
        (_cropRectN.top * sourceImage.height).round().toDouble(),
        (_cropRectN.right * sourceImage.width).round().toDouble(),
        (_cropRectN.bottom * sourceImage.height).round().toDouble(),
      );

      final clampedRect = Rect.fromLTRB(
        cropRect.left.clamp(0.0, sourceImage.width.toDouble()),
        cropRect.top.clamp(0.0, sourceImage.height.toDouble()),
        cropRect.right.clamp(0.0, sourceImage.width.toDouble()),
        cropRect.bottom.clamp(0.0, sourceImage.height.toDouble()),
      );

      if (clampedRect.width > 0 && clampedRect.height > 0) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        canvas.drawImageRect(
          sourceImage,
          clampedRect,
          Rect.fromLTWH(0, 0, clampedRect.width, clampedRect.height),
          Paint(),
        );

        final picture = recorder.endRecording();
        resultImage = await picture.toImage(
          clampedRect.width.round(),
          clampedRect.height.round(),
        );
      }

      // Step 2: Apply rotation to the cropped image
      if (_rotationAngle != 0.0) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final fullWidth = resultImage.width.toDouble();
        final fullHeight = resultImage.height.toDouble();

        // For rotation, we need a larger canvas to fit the rotated image
        final cos = math.cos(_rotationAngle).abs();
        final sin = math.sin(_rotationAngle).abs();
        final newWidth = fullWidth * cos + fullHeight * sin;
        final newHeight = fullWidth * sin + fullHeight * cos;

        // Translate to center, rotate, then translate back
        canvas.translate(newWidth / 2, newHeight / 2);
        canvas.rotate(_rotationAngle);
        canvas.translate(-fullWidth / 2, -fullHeight / 2);

        // Draw the rotated image
        canvas.drawImage(resultImage, Offset.zero, Paint());

        final picture = recorder.endRecording();
        resultImage = await picture.toImage(newWidth.round(), newHeight.round());
      }

      // Step 2.5: Apply corner offsets (4-point free transform) to the rotated image
      if (_cornerOffsetTL != Offset.zero || _cornerOffsetTR != Offset.zero || _cornerOffsetBL != Offset.zero || _cornerOffsetBR != Offset.zero) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final fullWidth = resultImage.width.toDouble();
        final fullHeight = resultImage.height.toDouble();

        // Calculate transformed corner positions
        final tl = Offset(
          _cornerOffsetTL.dx * fullWidth,
          _cornerOffsetTL.dy * fullHeight,
        );
        final tr = Offset(
          fullWidth + _cornerOffsetTR.dx * fullWidth,
          _cornerOffsetTR.dy * fullHeight,
        );
        final br = Offset(
          fullWidth + _cornerOffsetBR.dx * fullWidth,
          fullHeight + _cornerOffsetBR.dy * fullHeight,
        );
        final bl = Offset(
          _cornerOffsetBL.dx * fullWidth,
          fullHeight + _cornerOffsetBL.dy * fullHeight,
        );

        // Calculate bounding box of transformed corners
        final minX = [tl.dx, tr.dx, br.dx, bl.dx].reduce((a, b) => a < b ? a : b);
        final maxX = [tl.dx, tr.dx, br.dx, bl.dx].reduce((a, b) => a > b ? a : b);
        final minY = [tl.dy, tr.dy, br.dy, bl.dy].reduce((a, b) => a < b ? a : b);
        final maxY = [tl.dy, tr.dy, br.dy, bl.dy].reduce((a, b) => a > b ? a : b);

        final newWidth = maxX - minX;
        final newHeight = maxY - minY;

        // Translate corners to positive coordinates
        final tlAdjusted = Offset(tl.dx - minX, tl.dy - minY);
        final trAdjusted = Offset(tr.dx - minX, tr.dy - minY);
        final brAdjusted = Offset(br.dx - minX, br.dy - minY);
        final blAdjusted = Offset(bl.dx - minX, bl.dy - minY);

        _drawTexturedQuad(
          canvas,
          image: resultImage,
          dstTL: tlAdjusted,
          dstTR: trAdjusted,
          dstBL: blAdjusted,
          dstBR: brAdjusted,
        );

        final picture = recorder.endRecording();
        resultImage = await picture.toImage(newWidth.round(), newHeight.round());
      }

      // Flip is now applied immediately to working image, so no flip step needed here

      setState(() {
        _workingImage = resultImage;
        _cropRectN = const Rect.fromLTWH(0, 0, 1, 1);
        _hasPendingCrop = false;
        // Reset transforms since they've been applied
        _rotationAngle = 0.0;
        _cornerOffsetTL = Offset.zero;
        _cornerOffsetTR = Offset.zero;
        _cornerOffsetBL = Offset.zero;
        _cornerOffsetBR = Offset.zero;
      });
    } catch (e) {
      // If crop fails, just reset the pending state
      setState(() => _hasPendingCrop = false);
    }
  }

  void _fitToScreen() {
    // Reset zoom and pan to fit the current image (with all applied changes) to screen
    // Does NOT reset transformations or working image - keeps all edits
    // Must account for rotation when calculating fit

    final r = _imageRect;
    if (r == null) {
      // Fallback if no image rect yet
      setState(() {
        _zoomScale = 1.0;
        _panOffset = Offset.zero;
      });
      return;
    }

    // Calculate the bounding box of the rotated image
    final w = r.width;
    final h = r.height;

    // For rotation, calculate the bounding box dimensions
    final cos = math.cos(_rotationAngle).abs();
    final sin = math.sin(_rotationAngle).abs();
    final rotatedWidth = w * cos + h * sin;
    final rotatedHeight = w * sin + h * cos;

    // Calculate the scale needed to fit the rotated bounding box
    // The painter already fits the unrotated image to canvas at scale 1.0
    // We need to scale down if the rotated bounds are larger
    final scaleX = w / rotatedWidth;
    final scaleY = h / rotatedHeight;
    final fitScale = math.min(scaleX, scaleY);

    // Calculate pan offset to keep image centered after scaling
    // When we scale around origin, we need to offset to re-center the image
    // panOffset = center * (1 - scale) keeps the center in place
    final center = r.center;
    final panOffset = Offset(
      center.dx * (1 - fitScale),
      center.dy * (1 - fitScale),
    );

    setState(() {
      _zoomScale = fitScale;
      _panOffset = panOffset;
    });
  }

  void _resetToOriginal() {
    // Reset everything back to the original image, removing all changes
    _resetCrop();
    _clearMeasurement();
    setState(() {
      _zoomScale = 1.0;
      _panOffset = Offset.zero;
      _rotationAngle = 0.0;
      _cornerOffsetTL = Offset.zero;
      _cornerOffsetTR = Offset.zero;
      _cornerOffsetBL = Offset.zero;
      _cornerOffsetBR = Offset.zero;
      _workingImage = null; // Reset to original image
      _hasPendingCrop = false;
    });
  }

  Future<void> _applyFlipHorizontal() async {
    final sourceImage = _currentImage;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final fullWidth = sourceImage.width.toDouble();
      final fullHeight = sourceImage.height.toDouble();

      canvas.save();
      canvas.translate(fullWidth / 2, fullHeight / 2);
      canvas.scale(-1.0, 1.0);
      canvas.translate(-fullWidth / 2, -fullHeight / 2);
      canvas.drawImage(sourceImage, Offset.zero, Paint());
      canvas.restore();

      final picture = recorder.endRecording();
      final resultImage = await picture.toImage(sourceImage.width, sourceImage.height);

      setState(() {
        _workingImage = resultImage;
      });
    } catch (e) {
      // If flip fails, do nothing
    }
  }

  Future<void> _applyFlipVertical() async {
    final sourceImage = _currentImage;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final fullWidth = sourceImage.width.toDouble();
      final fullHeight = sourceImage.height.toDouble();

      canvas.save();
      canvas.translate(fullWidth / 2, fullHeight / 2);
      canvas.scale(1.0, -1.0);
      canvas.translate(-fullWidth / 2, -fullHeight / 2);
      canvas.drawImage(sourceImage, Offset.zero, Paint());
      canvas.restore();

      final picture = recorder.endRecording();
      final resultImage = await picture.toImage(sourceImage.width, sourceImage.height);

      setState(() {
        _workingImage = resultImage;
      });
    } catch (e) {
      // If flip fails, do nothing
    }
  }

  void _handlePanZoomStart(PointerPanZoomStartEvent e) {
    _panZoomStartScale = _zoomScale;
    _panZoomStartPan = _panOffset;
    _panZoomStartFocal = e.position;
  }

  void _handlePanZoomUpdate(PointerPanZoomUpdateEvent e) {
    final double nextScale = (_panZoomStartScale * e.scale).clamp(minZoom, maxZoom);
    final double zf = nextScale / _panZoomStartScale;
    setState(() {
      _panOffset = (_panZoomStartPan - _panZoomStartFocal) * zf + _panZoomStartFocal + e.pan;
      _zoomScale = nextScale;
    });
  }

  void _handlePointerDown(PointerDownEvent e) {
    if (e.kind == PointerDeviceKind.mouse && e.buttons == kMiddleMouseButton) {
      _isMiddleMousePanning = true;
      _middleMousePanStart = e.localPosition;
      _middleMousePanOffset = _panOffset;
    }
  }

  void _handlePointerMove(PointerMoveEvent e) {
    if (_isMiddleMousePanning) {
      final delta = e.localPosition - _middleMousePanStart;
      setState(() {
        _panOffset = _middleMousePanOffset + delta;
      });
    }
  }

  void _handlePointerUp(PointerUpEvent e) {
    if (_isMiddleMousePanning) {
      _isMiddleMousePanning = false;
    }
  }

  // ---------- image cropping ----------
  Future<ui.Image?> _getCroppedImage() async {
    ui.Image sourceImage = _currentImage;

    // The _cropRectN coordinates are in the UNROTATED image coordinate space
    // (because _onCropPanUpdate applies inverse rotation when calculating crop handles).
    // So we must: 1) Crop first, 2) Then rotate, 3) Then flip

    // Step 1: Apply cropping FIRST (in unrotated coordinate space)
    final cropRect = Rect.fromLTRB(
      (_cropRectN.left * sourceImage.width).round().toDouble(),
      (_cropRectN.top * sourceImage.height).round().toDouble(),
      (_cropRectN.right * sourceImage.width).round().toDouble(),
      (_cropRectN.bottom * sourceImage.height).round().toDouble(),
    );

    // Ensure crop rect is within image bounds
    final clampedRect = Rect.fromLTRB(
      cropRect.left.clamp(0.0, sourceImage.width.toDouble()),
      cropRect.top.clamp(0.0, sourceImage.height.toDouble()),
      cropRect.right.clamp(0.0, sourceImage.width.toDouble()),
      cropRect.bottom.clamp(0.0, sourceImage.height.toDouble()),
    );

    // Apply crop if needed
    final needsCrop = !(clampedRect.left <= 0 && clampedRect.top <= 0 && clampedRect.right >= sourceImage.width && clampedRect.bottom >= sourceImage.height);

    if (needsCrop) {
      try {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final outputWidth = clampedRect.width;
        final outputHeight = clampedRect.height;

        canvas.drawImageRect(
          sourceImage,
          clampedRect,
          Rect.fromLTWH(0, 0, outputWidth, outputHeight),
          Paint(),
        );

        final picture = recorder.endRecording();
        sourceImage = await picture.toImage(
          outputWidth.round(),
          outputHeight.round(),
        );
      } catch (e) {
        // If cropping fails, continue with original
      }
    }

    // Step 2: Apply rotation (if any) to the cropped image
    if (_rotationAngle != 0.0) {
      try {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final fullWidth = sourceImage.width.toDouble();
        final fullHeight = sourceImage.height.toDouble();

        // For rotation, we need a larger canvas to fit the rotated image
        final cos = math.cos(_rotationAngle).abs();
        final sin = math.sin(_rotationAngle).abs();
        final newWidth = fullWidth * cos + fullHeight * sin;
        final newHeight = fullWidth * sin + fullHeight * cos;

        // Translate to center, rotate, then translate back
        canvas.translate(newWidth / 2, newHeight / 2);
        canvas.rotate(_rotationAngle);
        canvas.translate(-fullWidth / 2, -fullHeight / 2);

        // Draw the rotated image
        canvas.drawImage(sourceImage, Offset.zero, Paint());

        final picture = recorder.endRecording();
        sourceImage = await picture.toImage(
          newWidth.round(),
          newHeight.round(),
        );
      } catch (e) {
        // If rotation fails, continue with current image
      }
    }

    // Step 2.5: Apply corner offsets (4-point free transform) to the rotated image
    if (_cornerOffsetTL != Offset.zero || _cornerOffsetTR != Offset.zero || _cornerOffsetBL != Offset.zero || _cornerOffsetBR != Offset.zero) {
      try {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final fullWidth = sourceImage.width.toDouble();
        final fullHeight = sourceImage.height.toDouble();

        // Calculate transformed corner positions
        final tl = Offset(
          _cornerOffsetTL.dx * fullWidth,
          _cornerOffsetTL.dy * fullHeight,
        );
        final tr = Offset(
          fullWidth + _cornerOffsetTR.dx * fullWidth,
          _cornerOffsetTR.dy * fullHeight,
        );
        final br = Offset(
          fullWidth + _cornerOffsetBR.dx * fullWidth,
          fullHeight + _cornerOffsetBR.dy * fullHeight,
        );
        final bl = Offset(
          _cornerOffsetBL.dx * fullWidth,
          fullHeight + _cornerOffsetBL.dy * fullHeight,
        );

        // Calculate bounding box of transformed corners
        final minX = [tl.dx, tr.dx, br.dx, bl.dx].reduce((a, b) => a < b ? a : b);
        final maxX = [tl.dx, tr.dx, br.dx, bl.dx].reduce((a, b) => a > b ? a : b);
        final minY = [tl.dy, tr.dy, br.dy, bl.dy].reduce((a, b) => a < b ? a : b);
        final maxY = [tl.dy, tr.dy, br.dy, bl.dy].reduce((a, b) => a > b ? a : b);

        final newWidth = maxX - minX;
        final newHeight = maxY - minY;

        // Translate corners to positive coordinates
        final tlAdjusted = Offset(tl.dx - minX, tl.dy - minY);
        final trAdjusted = Offset(tr.dx - minX, tr.dy - minY);
        final brAdjusted = Offset(br.dx - minX, br.dy - minY);
        final blAdjusted = Offset(bl.dx - minX, bl.dy - minY);

        _drawTexturedQuad(
          canvas,
          image: sourceImage,
          dstTL: tlAdjusted,
          dstTR: trAdjusted,
          dstBL: blAdjusted,
          dstBR: brAdjusted,
        );

        final picture = recorder.endRecording();
        sourceImage = await picture.toImage(
          newWidth.round(),
          newHeight.round(),
        );
      } catch (e) {
        // If corner transform fails, continue with current image
      }
    }

    // Flip is now applied immediately to working image, so no flip step needed here

    return sourceImage;
  }

  void _completeCalibration() async {
    if (_startPointNormalized == null || _endPointNormalized == null || _distanceController.text.trim().isEmpty) {
      return;
    }

    final distance = double.tryParse(_distanceController.text.trim()) ?? 0;
    if (distance <= 0) return;

    final startPx = _normalizedToImagePx(_startPointNormalized!);
    final endPx = _normalizedToImagePx(_endPointNormalized!);

    // Generate cropped image
    final croppedImage = await _getCroppedImage();

    final data = CalibrationData(
      startPoint: startPx,
      endPoint: endPx,
      realWorldDistance: distance,
      unit: _selectedUnit,
      imageSize: Size(
        _currentImage.width.toDouble(),
        _currentImage.height.toDouble(),
      ),
      croppedImage: croppedImage,
    );
    widget.onCalibrationComplete(data);

    // ignore: use_build_context_synchronously
    fusionLibLocator<GuideShowCaseController>().completeStep(
      GuideShowCaseSteps.confirmFloorCalibrated,
    );
  }

  final GlobalKey _customPaintKey = GlobalKey();

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final imageInvalid = _currentImage.width <= 0 || _currentImage.height <= 0;

    if (imageInvalid) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 48,
            ),
            const SizedBox(height: 12),
            FusionAppText(
              text: 'Invalid image',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            FusionAppText(
              text: 'Image dimensions: ${_currentImage.width}×${_currentImage.height}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            FusionOutlinedButton(
              accessLabel: 'floor_plan_calibration_cancel',
              label: 'Close',
              onTap: () => widget.onCancel?.call(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.colorScheme.strokeLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: <Widget>[
                  // Toolbar row
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      spacing: 8,
                      children: <Widget>[
                        // Left: tool icons
                        _ToolbarIcon(
                          icon: LucideIcons.rulerDimensionLine200,
                          seemanticKey: FusionTestKeys.measureScale,
                          tooltip: 'Measure scale (draw line)',
                          active: _mode == _ToolMode.measure,
                          enabled: !_hasPendingSkew && !_hasPendingCrop,
                          onTap: () => setState(() => _mode = _ToolMode.measure),
                        ),
                        _ToolbarIcon(
                          icon: LucideIcons.crop200,
                          seemanticKey: FusionTestKeys.cropImage,
                          tooltip: 'Crop',
                          active: _mode == _ToolMode.crop,
                          enabled: !_hasPendingSkew,
                          onTap: () => setState(() => _mode = _ToolMode.crop),
                        ),
                        _ToolbarIcon(
                          icon: LucideIcons.rotateCcw200,
                          seemanticKey: FusionTestKeys.rotateImage,
                          tooltip: 'Rotate',
                          active: _mode == _ToolMode.rotate,
                          enabled: !_hasPendingSkew && !_hasPendingCrop,
                          onTap: () => setState(() => _mode = _ToolMode.rotate),
                        ),

                        _ToolbarIcon(
                          icon: LucideIcons.flipHorizontal2200,
                          seemanticKey: FusionTestKeys.flipHorizontal,
                          tooltip: 'Flip Horizontal',
                          enabled: !_hasPendingSkew && !_hasPendingCrop,
                          onTap: _applyFlipHorizontal,
                        ),
                        _ToolbarIcon(
                          icon: LucideIcons.flipVertical2200,
                          seemanticKey: FusionTestKeys.flipVertical,
                          tooltip: 'Flip Vertical',
                          enabled: !_hasPendingSkew && !_hasPendingCrop,
                          onTap: _applyFlipVertical,
                        ),
                        _ToolbarIcon(
                          svgIcon: "packages/fusion_lib/lib/assets/svgs/skew.svg",
                          seemanticKey: FusionTestKeys.skew,
                          tooltip: 'Skew',
                          active: _mode == _ToolMode.skew,
                          enabled: !_hasPendingCrop,
                          onTap: () => setState(() => _mode = _ToolMode.skew),
                        ),
                        _ToolbarIcon(
                          svgIcon: "packages/fusion_lib/lib/assets/svgs/reset.svg",
                          seemanticKey: FusionTestKeys.reset,
                          tooltip: 'Reset to original',
                          enabled: !_hasPendingSkew && !_hasPendingCrop,
                          onTap: _resetToOriginal,
                        ),
                        _ToolbarIcon(
                          seemanticKey: FusionTestKeys.fitToScreen,
                          icon: LucideIcons.expand200,
                          tooltip: 'Fit to screen',
                          enabled: !_hasPendingSkew && !_hasPendingCrop,
                          onTap: () => _fitToScreen(),
                        ),
                        Spacer(),
                        // Rotate Left/Right buttons (visible when in rotate mode)
                        if (_mode == _ToolMode.rotate) ...<Widget>[
                          _ToolbarIcon(
                            icon: LucideIcons.rotateCcw200,
                            seemanticKey: FusionTestKeys.rotateLeft,
                            tooltip: 'Rotate Left (90°)',
                            onTap: _rotateLeft,
                          ),
                          _ToolbarIcon(
                            icon: LucideIcons.rotateCw200,
                            seemanticKey: FusionTestKeys.rotateRight,
                            tooltip: 'Rotate Right (90°)',
                            onTap: _rotateRight,
                          ),
                        ],

                        // Crop confirm/cancel buttons (visible when in crop mode with pending crop)
                        if (_mode == _ToolMode.crop && _hasPendingCrop) ...<Widget>[
                          _ToolbarIcon(
                            icon: LucideIcons.check200,
                            seemanticKey: FusionTestKeys.cropConfirm,
                            tooltip: 'Apply Crop',
                            onTap: _applyCrop,
                          ),
                          _ToolbarIcon(
                            icon: LucideIcons.x200,
                            seemanticKey: FusionTestKeys.cropCancel,
                            tooltip: 'Cancel Crop',
                            onTap: _cancelCrop,
                          ),
                        ],

                        // Skew reset/apply buttons (visible when in skew mode with pending skew)
                        if (_mode == _ToolMode.skew && _hasPendingSkew) ...<Widget>[
                          _ToolbarIcon(
                            icon: LucideIcons.check200,
                            seemanticKey: FusionTestKeys.skewApply,
                            tooltip: 'Apply Skew',
                            onTap: _applySkew,
                          ),
                          _ToolbarIcon(
                            icon: LucideIcons.x200,
                            seemanticKey: FusionTestKeys.skewReset,
                            tooltip: 'Cancel Skew',
                            onTap: _cancelSkew,
                          ),
                        ],
                        const Spacer(),
                        // Right: distance + units controls
                        FusionAppText(
                          text: 'Distance',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(
                          width: 96,
                          child: SemanticHelper.formControl(
                            testId: SemanticHelper.createTestId(SemanticTypes.textInput, FusionTestKeys.calibrationDistance),
                            child: PropertyTextField(
                              controller: _distanceController,
                              hintText: '1.00',
                              textAlign: TextAlign.right,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FusionAppText(
                          text: 'Units',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: FusionDropdown2<MeasurementUnit>(
                            padding: EdgeInsets.all(6),
                            borderRadius: 6,
                            selectedValue: _selectedUnit,
                            items: MeasurementUnit.values,
                            labelBuilder: (item) => '${item.displayName} (${item.symbol})',
                            onChanged: (MeasurementUnit value) {
                              setState(() => _selectedUnit = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Canvas
                  Expanded(
                    child: Listener(
                      onPointerSignal: _handleScrollWheelZoom,
                      onPointerPanZoomStart: _handlePanZoomStart,
                      onPointerPanZoomUpdate: _handlePanZoomUpdate,
                      onPointerDown: _handlePointerDown,
                      onPointerMove: _handlePointerMove,
                      onPointerUp: _handlePointerUp,
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(),
                        child: MouseRegion(
                          cursor: switch (_mode) {
                            _ToolMode.measure => SystemMouseCursors.precise,
                            _ToolMode.rotate => (_isRotating ? SystemMouseCursors.grabbing : SystemMouseCursors.alias),
                            _ToolMode.skew => (_isSkewing ? SystemMouseCursors.grabbing : SystemMouseCursors.grab),
                            _ => SystemMouseCursors.resizeUpLeftDownRight,
                          },
                          onHover: _mode == _ToolMode.measure ? _onMeasureHover : null,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: _mode == _ToolMode.measure ? _onMeasureTapDown : null,
                            onPanStart: switch (_mode) {
                              _ToolMode.crop => _onCropPanStart,
                              _ToolMode.rotate => _onRotatePanStart,
                              _ToolMode.skew => _onSkewPanStart,
                              _ => null,
                            },
                            onPanUpdate: switch (_mode) {
                              _ToolMode.measure => _onMeasurePanUpdate,
                              _ToolMode.crop => _onCropPanUpdate,
                              _ToolMode.rotate => _onRotatePanUpdate,
                              _ToolMode.skew => _onSkewPanUpdate,
                            },
                            onPanEnd: (d) {
                              if (_mode == _ToolMode.crop) _onCropPanEnd(d);
                              if (_mode == _ToolMode.rotate) _onRotatePanEnd(d);
                              if (_mode == _ToolMode.skew) _onSkewPanEnd(d);
                              if (_mode == _ToolMode.measure && _isDrawing) {
                                setState(() => _isDrawing = false);
                              }
                            },
                            child: GuideShowcaseWrapper(
                              semanticId: "guide_showcase_floor_calibration",
                              step: GuideShowCaseSteps.showFloorPickCalibration,
                              onHighlightedSpotTap: (TapDownDetails details) {
                                if (_mode == _ToolMode.measure) {
                                  // Get the exact RenderBox of the CustomPaint
                                  final RenderBox? renderBox = _customPaintKey.currentContext?.findRenderObject() as RenderBox?;
                                  if (renderBox != null) {
                                    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);

                                    // Create new TapDownDetails with local position
                                    final TapDownDetails localDetails = TapDownDetails(
                                      globalPosition: details.globalPosition,
                                      localPosition: localPosition,
                                      kind: details.kind,
                                    );

                                    _onMeasureTapDown(localDetails);
                                  }
                                }
                              },
                              child: Center(
                                child: SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.floorCalibrationCanvas),
                                  child: CustomPaint(
                                    key: _customPaintKey,
                                    painter: FloorPlanCalibrationPainter(
                                      image: _currentImage,
                                      startPoint: _startPointDisplay,
                                      endPoint: _endPointDisplay,
                                      distanceText: _distanceController.text.trim(),
                                      unit: _selectedUnit,
                                      cropRectNormalized: _cropRectN,
                                      showCropHandles: _mode == _ToolMode.crop,
                                      showRotationHandles: _mode == _ToolMode.rotate,
                                      showSkewHandles: _mode == _ToolMode.skew,
                                      rotationAngle: _rotationAngle,
                                      cornerOffsetTL: _cornerOffsetTL,
                                      cornerOffsetTR: _cornerOffsetTR,
                                      cornerOffsetBL: _cornerOffsetBL,
                                      cornerOffsetBR: _cornerOffsetBR,
                                      zoomScale: _zoomScale,
                                      panOffset: _panOffset,
                                      flipHorizontal: false,
                                      flipVertical: false,
                                      onImageRectChanged: (ui.Rect r) {
                                        _imageRect = r;
                                        // keep display points in sync if image rect changes
                                        if (_startPointNormalized != null) {
                                          _startPointDisplay = _normalizedToCanvas(_startPointNormalized!);
                                        }
                                        if (_endPointNormalized != null) {
                                          _endPointDisplay = _normalizedToCanvas(_endPointNormalized!);
                                        }
                                      },
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
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
        ),

        Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              const Spacer(),
              FusionOutlinedButton(
                accessLabel: 'floor_plan_calibration_cancel',
                width: 120,
                height: 36,
                borderRadius: 12,
                label: "Cancel",
                onTap: () {
                  widget.onCancel!();
                },
              ),
              const SizedBox(width: 8),
              GuideShowcaseWrapper(
                semanticId: 'floor_plan_calibrator_confirm',
                step: GuideShowCaseSteps.confirmFloorCalibrated,
                onHighlightedSpotTap: (TapDownDetails details) {
                  if (_startPointNormalized != null && _endPointNormalized != null && _distanceController.text.trim().isNotEmpty) {
                    _completeCalibration();
                  }
                },
                child: FusionButton(
                  accessLabel: "floor_plan_calibrator_confirm",
                  label: "Confirm",
                  width: 120,
                  height: 36,
                  borderRadius: 12,
                  textStyle: context.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  activeBackgroundColor: context.colorScheme.primaryColor,
                  onTap: () {
                    if (_startPointNormalized != null && _endPointNormalized != null && _distanceController.text.trim().isNotEmpty) {
                      _completeCalibration();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData? icon;
  final String? svgIcon;
  final String tooltip;
  final String seemanticKey;
  final VoidCallback? onTap;
  final bool active;
  final bool enabled;

  const _ToolbarIcon({
    this.icon,
    this.svgIcon,
    required this.tooltip,
    required this.seemanticKey,
    this.onTap,
    this.active = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, seemanticKey),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: Tooltip(
          message: tooltip,
          child: InkResponse(
            onTap: enabled ? onTap : null,
            radius: 22,
            child: Container(
              width: 28,
              height: 28,
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: enabled ? (active ? context.colorScheme.elevation3 : null) : null,
                border: Border.all(
                  color: enabled ? context.colorScheme.elevation4 : context.colorScheme.elevation3,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FittedBox(
                child: Builder(
                  builder: (context) {
                    if (svgIcon != null) {
                      return FusionSvgIcon(
                        icon: svgIcon!,
                        color: enabled ? (active ? context.colorScheme.primaryWhite : context.colorScheme.iconDefault) : context.colorScheme.elevation5,
                      );
                    }
                    return Icon(
                      icon,
                      size: 16,
                      color: enabled ? (active ? context.colorScheme.primaryWhite : context.colorScheme.iconDefault) : context.colorScheme.elevation5,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CropHandle {
  none,
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

enum _RotationHandle {
  none,
  topLeft,
  topRight,
  bottomRight,
  bottomLeft,
}

// Transform handles: 4 corners for independent movement + 4 edge midpoints for paired movement
enum _SkewHandle {
  none,
  // Edge handles (move two corners together)
  topCenter, // move topLeft and topRight together
  bottomCenter, // move bottomLeft and bottomRight together
  leftCenter, // move topLeft and bottomLeft together
  rightCenter, // move topRight and bottomRight together
  // Corner handles (independent movement)
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Builds a subdivided triangle mesh that maps a source rectangle to an
/// arbitrary destination quadrilateral using bilinear interpolation.
///
/// With only 2 triangles the GPU does per-triangle affine interpolation,
/// which creates a visible diagonal seam and looks like perspective
/// distortion. Subdividing into [divisions]×[divisions] cells (default 10)
/// produces 200 tiny triangles whose bilinear UV mapping is visually
/// smooth — no perspective artifact.
ui.Vertices _buildSubdividedQuadVertices({
  required Offset dstTL,
  required Offset dstTR,
  required Offset dstBL,
  required Offset dstBR,
  required double srcWidth,
  required double srcHeight,
  int divisions = 10,
}) {
  final int cols = divisions;
  final int rows = divisions;
  final int vertexCount = (cols + 1) * (rows + 1);
  final int triangleCount = cols * rows * 2;

  final positions = Float32List(vertexCount * 2);
  final texCoords = Float32List(vertexCount * 2);
  final indices = Uint16List(triangleCount * 3);

  // Build grid vertices with bilinear interpolation
  int vi = 0;
  for (int r = 0; r <= rows; r++) {
    final double v = r / rows; // 0..1 vertically
    // Lerp left edge and right edge
    final leftX = dstTL.dx + (dstBL.dx - dstTL.dx) * v;
    final leftY = dstTL.dy + (dstBL.dy - dstTL.dy) * v;
    final rightX = dstTR.dx + (dstBR.dx - dstTR.dx) * v;
    final rightY = dstTR.dy + (dstBR.dy - dstTR.dy) * v;

    for (int c = 0; c <= cols; c++) {
      final double u = c / cols; // 0..1 horizontally
      // Bilinear position
      positions[vi * 2] = leftX + (rightX - leftX) * u;
      positions[vi * 2 + 1] = leftY + (rightY - leftY) * u;
      // Texture coordinate
      texCoords[vi * 2] = srcWidth * u;
      texCoords[vi * 2 + 1] = srcHeight * v;
      vi++;
    }
  }

  // Build triangle indices
  int ii = 0;
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final int i = r * (cols + 1) + c;
      // Triangle 1
      indices[ii++] = i;
      indices[ii++] = i + 1;
      indices[ii++] = i + cols + 1;
      // Triangle 2
      indices[ii++] = i + 1;
      indices[ii++] = i + cols + 2;
      indices[ii++] = i + cols + 1;
    }
  }

  return ui.Vertices.raw(
    VertexMode.triangles,
    _expandIndexed(positions, indices),
    textureCoordinates: _expandIndexed(texCoords, indices),
  );
}

/// Expands indexed vertex data into non-indexed triangle list.
Float32List _expandIndexed(Float32List data, Uint16List indices) {
  final result = Float32List(indices.length * 2);
  for (int i = 0; i < indices.length; i++) {
    final idx = indices[i];
    result[i * 2] = data[idx * 2];
    result[i * 2 + 1] = data[idx * 2 + 1];
  }
  return result;
}

/// Draws a textured quadrilateral on [canvas] by subdividing into a grid mesh.
void _drawTexturedQuad(
  Canvas canvas, {
  required ui.Image image,
  required Offset dstTL,
  required Offset dstTR,
  required Offset dstBL,
  required Offset dstBR,
  double? srcWidth,
  double? srcHeight,
}) {
  final sw = srcWidth ?? image.width.toDouble();
  final sh = srcHeight ?? image.height.toDouble();

  final vertices = _buildSubdividedQuadVertices(
    dstTL: dstTL,
    dstTR: dstTR,
    dstBL: dstBL,
    dstBR: dstBR,
    srcWidth: sw,
    srcHeight: sh,
  );

  final shader = ImageShader(
    image,
    TileMode.clamp,
    TileMode.clamp,
    Matrix4.identity().storage,
    filterQuality: FilterQuality.high,
  );

  canvas.drawVertices(
    vertices,
    BlendMode.srcOver,
    Paint()..shader = shader,
  );
}

class FloorPlanCalibrationPainter extends CustomPainter {
  final ui.Image image;
  final Offset? startPoint;
  final Offset? endPoint;
  final String distanceText;
  final MeasurementUnit unit;
  final Rect? cropRectNormalized; // 0..1 inside the displayed image rect
  final bool showCropHandles;
  final bool showRotationHandles;
  final bool showSkewHandles;
  final double rotationAngle;
  // 4-point free transform corner offsets (normalized)
  final Offset cornerOffsetTL;
  final Offset cornerOffsetTR;
  final Offset cornerOffsetBL;
  final Offset cornerOffsetBR;
  final double zoomScale;
  final Offset panOffset;
  final bool flipHorizontal;
  final bool flipVertical;
  final Function(Rect)? onImageRectChanged;

  FloorPlanCalibrationPainter({
    required this.image,
    this.startPoint,
    this.endPoint,
    this.distanceText = '',
    required this.unit,
    this.cropRectNormalized,
    this.showCropHandles = false,
    this.showRotationHandles = false,
    this.showSkewHandles = false,
    this.rotationAngle = 0.0,
    this.cornerOffsetTL = Offset.zero,
    this.cornerOffsetTR = Offset.zero,
    this.cornerOffsetBL = Offset.zero,
    this.cornerOffsetBR = Offset.zero,
    this.zoomScale = 1.0,
    this.panOffset = Offset.zero,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.onImageRectChanged,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (image.width <= 0 || image.height <= 0) return;

    // Apply pan/zoom
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomScale, zoomScale);

    final imageAR = image.width / image.height;
    final canvasAR = size.width / size.height;

    // fit image into canvas preserving AR
    late Size scaled;
    late Offset off;
    if (imageAR > canvasAR) {
      scaled = Size(size.width, size.width / imageAR);
      off = Offset(0, (size.height - scaled.height) / 2);
    } else {
      scaled = Size(size.height * imageAR, size.height);
      off = Offset((size.width - scaled.width) / 2, 0);
    }
    final Rect imageRect = off & scaled;

    onImageRectChanged?.call(imageRect);

    // Calculate 4-point transform corners (base corners + offsets)
    final w = imageRect.width;
    final h = imageRect.height;
    var topLeft = imageRect.topLeft + Offset(cornerOffsetTL.dx * w, cornerOffsetTL.dy * h);
    var topRight = imageRect.topRight + Offset(cornerOffsetTR.dx * w, cornerOffsetTR.dy * h);
    var bottomLeft = imageRect.bottomLeft + Offset(cornerOffsetBL.dx * w, cornerOffsetBL.dy * h);
    var bottomRight = imageRect.bottomRight + Offset(cornerOffsetBR.dx * w, cornerOffsetBR.dy * h);

    // Center for transforms
    final cx = imageRect.left + w / 2;
    final cy = imageRect.top + h / 2;

    // Helper to rotate a point around center
    Offset rotatePoint(Offset p, double cos, double sin) {
      final dx = p.dx - cx;
      final dy = p.dy - cy;
      return Offset(cx + dx * cos - dy * sin, cy + dx * sin + dy * cos);
    }

    // Helper to flip a point around center
    Offset flipPoint(Offset p) {
      final dx = p.dx - cx;
      final dy = p.dy - cy;
      return Offset(
        cx + (flipHorizontal ? -dx : dx),
        cy + (flipVertical ? -dy : dy),
      );
    }

    // Apply rotation if needed
    if (rotationAngle != 0.0) {
      final cos = math.cos(rotationAngle);
      final sin = math.sin(rotationAngle);
      topLeft = rotatePoint(topLeft, cos, sin);
      topRight = rotatePoint(topRight, cos, sin);
      bottomLeft = rotatePoint(bottomLeft, cos, sin);
      bottomRight = rotatePoint(bottomRight, cos, sin);
    }

    // Apply flip if needed (after rotation)
    if (flipHorizontal || flipVertical) {
      topLeft = flipPoint(topLeft);
      topRight = flipPoint(topRight);
      bottomLeft = flipPoint(bottomLeft);
      bottomRight = flipPoint(bottomRight);

      // Swap corners if flipped to maintain correct vertex order
      if (flipHorizontal) {
        final tempL = topLeft;
        final tempBL = bottomLeft;
        topLeft = topRight;
        topRight = tempL;
        bottomLeft = bottomRight;
        bottomRight = tempBL;
      }
      if (flipVertical) {
        final tempT = topLeft;
        final tempTR = topRight;
        topLeft = bottomLeft;
        bottomLeft = tempT;
        topRight = bottomRight;
        bottomRight = tempTR;
      }
    }

    // Check if we have any corner offsets (4-point transform needed)
    final hasCornerOffsets = cornerOffsetTL != Offset.zero || cornerOffsetTR != Offset.zero || cornerOffsetBL != Offset.zero || cornerOffsetBR != Offset.zero;

    if (hasCornerOffsets) {
      // Render image as textured quadrilateral using subdivided grid mesh
      _drawTexturedQuad(
        canvas,
        image: image,
        dstTL: topLeft,
        dstTR: topRight,
        dstBL: bottomLeft,
        dstBR: bottomRight,
      );
    } else {
      // No corner offsets - use simple drawImageRect with rotation/flip
      if (rotationAngle != 0.0) {
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(rotationAngle);
        canvas.translate(-cx, -cy);
      }

      if (flipHorizontal || flipVertical) {
        canvas.save();
        canvas.translate(cx, cy);
        canvas.scale(flipHorizontal ? -1.0 : 1.0, flipVertical ? -1.0 : 1.0);
        canvas.translate(-cx, -cy);
      }

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        imageRect,
        Paint()..filterQuality = FilterQuality.high,
      );

      if (flipHorizontal || flipVertical) {
        canvas.restore();
      }

      if (rotationAngle != 0.0) {
        canvas.restore();
      }
    }

    // --- rotation handles (4 corners) ---
    if (showRotationHandles) {
      final cos = math.cos(rotationAngle);
      final sin = math.sin(rotationAngle);

      Offset rotatePoint(Offset p) {
        final dx = p.dx - cx;
        final dy = p.dy - cy;
        return Offset(
          cx + dx * cos - dy * sin,
          cy + dx * sin + dy * cos,
        );
      }

      final corners = <Offset>[
        rotatePoint(imageRect.topLeft),
        rotatePoint(imageRect.topRight),
        rotatePoint(imageRect.bottomRight),
        rotatePoint(imageRect.bottomLeft),
      ];

      // Draw bounding box outline
      final boundingPath = Path()
        ..moveTo(corners[0].dx, corners[0].dy)
        ..lineTo(corners[1].dx, corners[1].dy)
        ..lineTo(corners[2].dx, corners[2].dy)
        ..lineTo(corners[3].dx, corners[3].dy)
        ..close();

      canvas.drawPath(
        boundingPath,
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );

      // Draw corner handles (scale inversely with zoom, clamped for visibility)
      const double baseHandleSize = 12;
      final double handleSize = (baseHandleSize / zoomScale).clamp(6.0, 18.0);
      final Paint handleFill = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final Paint handleStroke = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.5 / zoomScale.clamp(0.5, 2.0)
        ..style = PaintingStyle.stroke;

      for (final corner in corners) {
        // Draw square handles with border
        final rect = Rect.fromCenter(center: corner, width: handleSize, height: handleSize);
        canvas.drawRect(rect, handleFill);
        canvas.drawRect(rect, handleStroke);
      }

      // Draw rotation angle indicator
      if (rotationAngle != 0.0) {
        final angleDeg = (rotationAngle * 180 / math.pi) % 360;
        final angleText = '${angleDeg.toStringAsFixed(1)}°';
        final tp = TextPainter(
          text: TextSpan(
            text: angleText,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        const double pad = 4;
        final Offset labPos = Offset(cx - tp.width / 2, cy - tp.height / 2);
        final RRect bg = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            labPos.dx - pad,
            labPos.dy - pad,
            tp.width + pad * 2,
            tp.height + pad * 2,
          ),
          const Radius.circular(4),
        );

        canvas.drawRRect(bg, Paint()..color = Colors.white.withValues(alpha: 0.9));
        tp.paint(canvas, labPos);
      }
    }

    // --- transform handles (8 handles: 4 corners + 4 edge midpoints) ---
    if (showSkewHandles) {
      final cos = math.cos(rotationAngle);
      final sin = math.sin(rotationAngle);

      // Calculate corner positions with offsets
      final w = imageRect.width;
      final h = imageRect.height;
      var tl = imageRect.topLeft + Offset(cornerOffsetTL.dx * w, cornerOffsetTL.dy * h);
      var tr = imageRect.topRight + Offset(cornerOffsetTR.dx * w, cornerOffsetTR.dy * h);
      var bl = imageRect.bottomLeft + Offset(cornerOffsetBL.dx * w, cornerOffsetBL.dy * h);
      var br = imageRect.bottomRight + Offset(cornerOffsetBR.dx * w, cornerOffsetBR.dy * h);

      // Apply rotation to corner positions
      Offset rotateP(Offset p) {
        final dx = p.dx - cx;
        final dy = p.dy - cy;
        return Offset(cx + dx * cos - dy * sin, cy + dx * sin + dy * cos);
      }

      tl = rotateP(tl);
      tr = rotateP(tr);
      bl = rotateP(bl);
      br = rotateP(br);

      // Calculate edge midpoints from actual corner positions
      final topMid = Offset((tl.dx + tr.dx) / 2, (tl.dy + tr.dy) / 2);
      final bottomMid = Offset((bl.dx + br.dx) / 2, (bl.dy + br.dy) / 2);
      final leftMid = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
      final rightMid = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);

      // Draw bounding quadrilateral
      final boundingPath = Path()
        ..moveTo(tl.dx, tl.dy)
        ..lineTo(tr.dx, tr.dy)
        ..lineTo(br.dx, br.dy)
        ..lineTo(bl.dx, bl.dy)
        ..close();

      canvas.drawPath(
        boundingPath,
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );

      // Handle dimensions (scale inversely with zoom, clamped for visibility)
      const double baseEdgeHandleWidth = 20;
      const double baseEdgeHandleHeight = 8;
      const double baseCornerHandleSize = 12;
      final double edgeHandleWidth = (baseEdgeHandleWidth / zoomScale).clamp(10.0, 30.0);
      final double edgeHandleHeight = (baseEdgeHandleHeight / zoomScale).clamp(4.0, 12.0);
      final double cornerHandleSize = (baseCornerHandleSize / zoomScale).clamp(6.0, 18.0);

      final Paint handleFill = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final Paint handleStroke = Paint()
        ..color = Colors.black
        ..strokeWidth = 2.5 / zoomScale.clamp(0.5, 2.0)
        ..style = PaintingStyle.stroke;

      // Draw corner handles (squares for independent corner movement)
      for (final pt in [tl, tr, bl, br]) {
        final rect = Rect.fromCenter(center: pt, width: cornerHandleSize, height: cornerHandleSize);
        canvas.drawRect(rect, handleFill);
        canvas.drawRect(rect, handleStroke);
      }

      // Draw top/bottom edge handles (horizontal rectangles)
      for (final pt in [topMid, bottomMid]) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: pt, width: edgeHandleWidth, height: edgeHandleHeight),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, handleFill);
        canvas.drawRRect(rect, handleStroke);
      }

      // Draw left/right edge handles (vertical rectangles)
      for (final pt in [leftMid, rightMid]) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: pt, width: edgeHandleHeight, height: edgeHandleWidth),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, handleFill);
        canvas.drawRRect(rect, handleStroke);
      }
    }

    // --- crop overlay + handles (like screenshot) ---
    if (cropRectNormalized != null) {
      final c = cropRectNormalized!;
      final Rect crop = Rect.fromLTRB(
        imageRect.left + c.left * imageRect.width,
        imageRect.top + c.top * imageRect.height,
        imageRect.left + c.right * imageRect.width,
        imageRect.top + c.bottom * imageRect.height,
      );

      // Apply rotation transform to crop overlay (same as image)
      if (rotationAngle != 0.0) {
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(rotationAngle);
        canvas.translate(-cx, -cy);
      }

      // darken outside
      final Path outside = Path()..addRect(Offset.zero & size);
      final Path hole = Path()..addRect(crop);
      final Path overlay = Path.combine(PathOperation.difference, outside, hole);
      canvas.drawPath(overlay, Paint()..color = Colors.transparent);

      // crop border
      final border = Paint()
        ..color = Colors.black
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawRect(crop, border);

      // corner + side handles
      if (showCropHandles) {
        final Map<_CropHandle, Offset> pts = {
          _CropHandle.topLeft: crop.topLeft,
          _CropHandle.top: Offset((crop.left + crop.right) / 2, crop.top),
          _CropHandle.topRight: crop.topRight,
          _CropHandle.right: Offset(crop.right, (crop.top + crop.bottom) / 2),
          _CropHandle.bottomRight: crop.bottomRight,
          _CropHandle.bottom: Offset((crop.left + crop.right) / 2, crop.bottom),
          _CropHandle.bottomLeft: crop.bottomLeft,
          _CropHandle.left: Offset(crop.left, (crop.top + crop.bottom) / 2),
        };

        // Scale crop handles inversely with zoom
        const double baseHandleSize = 12;
        final double handleSize = (baseHandleSize / zoomScale).clamp(6.0, 18.0);
        final Paint hp = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final Paint hb = Paint()
          ..color = Colors.black
          ..strokeWidth = 2.5 / zoomScale.clamp(0.5, 2.0)
          ..style = PaintingStyle.stroke;

        for (final p in pts.values) {
          final r = Rect.fromCenter(center: p, width: handleSize, height: handleSize);
          canvas.drawRect(r, hp);
          canvas.drawRect(r, hb);
        }
      }

      if (rotationAngle != 0.0) {
        canvas.restore();
      }
    }

    // --- measurement line with arrowheads + pill label ---
    if (startPoint != null && endPoint != null) {
      final p1 = startPoint!;
      final p2 = endPoint!;
      if ((p2 - p1).distance <= 0.1) return;

      final base = Paint()
        ..color = Colors.black
        ..strokeWidth = 2.5;
      // ..style = PaintingStyle.stroke;

      // final guide = Paint()
      //   ..color = Colors.black
      //   ..strokeWidth = 6
      //   ..style = PaintingStyle.stroke;

      // // draw white guide underlay for contrast
      // canvas.drawLine(p1, p2, guide);
      // main line
      canvas.drawLine(p1, p2, base);

      // arrowheads
      _drawArrowHead(canvas, p1, p2, base);
      _drawArrowHead(canvas, p2, p1, base);

      // label (black rounded pill)
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final String label = distanceText.isNotEmpty ? '$distanceText ${unit.symbol}' : '1 ${unit.symbol}';

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      const double pad = 6;
      final Offset labPos = Offset(
        mid.dx - tp.width / 2,
        mid.dy - 28 - tp.height / 2,
      );
      final RRect bg = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labPos.dx - pad,
          labPos.dy - pad,
          tp.width + pad * 2,
          tp.height + pad * 2,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        bg,
        Paint()..color = Colors.black.withValues(alpha: 0.8),
      );
      tp.paint(canvas, labPos);
    }
    canvas.restore();
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint p) {
    // arrow pointing from -> to
    const double len = 10;
    const double angle = 28 * math.pi / 180;

    final dir = (to - from);
    final d = dir.distance;
    if (d <= 0.001) return;
    final ux = dir.dx / d;
    final uy = dir.dy / d;

    // rotate (-angle) and (+angle)
    Offset rot(double a) => Offset(
      ux * math.cos(a) - uy * math.sin(a),
      ux * math.sin(a) + uy * math.cos(a),
    );

    final a1 = from + rot(angle) * len;
    final a2 = from + rot(-angle) * len;

    canvas.drawLine(from, a1, p);
    canvas.drawLine(from, a2, p);
  }

  @override
  bool shouldRepaint(covariant FloorPlanCalibrationPainter old) =>
      old.image != image ||
      old.startPoint != startPoint ||
      old.endPoint != endPoint ||
      old.distanceText != distanceText ||
      old.unit != unit ||
      old.cropRectNormalized != cropRectNormalized ||
      old.showCropHandles != showCropHandles ||
      old.showRotationHandles != showRotationHandles ||
      old.showSkewHandles != showSkewHandles ||
      old.rotationAngle != rotationAngle ||
      old.cornerOffsetTL != cornerOffsetTL ||
      old.cornerOffsetTR != cornerOffsetTR ||
      old.cornerOffsetBL != cornerOffsetBL ||
      old.cornerOffsetBR != cornerOffsetBR ||
      old.zoomScale != zoomScale ||
      old.panOffset != panOffset ||
      old.flipHorizontal != flipHorizontal ||
      old.flipVertical != flipVertical;
}

class CalibrationData {
  final Offset startPoint;
  final Offset endPoint;
  final double realWorldDistance;
  final MeasurementUnit unit;
  final Size imageSize;
  final ui.Image? croppedImage;

  CalibrationData({
    required this.startPoint,
    required this.endPoint,
    required this.realWorldDistance,
    required this.unit,
    required this.imageSize,
    this.croppedImage,
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

  double get pixelDistance => (endPoint - startPoint).distance;

  double get pixelsPerUnit => pixelDistance > 0 && realWorldDistance > 0 ? pixelDistance / realWorldDistance : 0;

  double get unitsPerPixel => pixelDistance > 0 && realWorldDistance > 0 ? realWorldDistance / pixelDistance : 0;

  double pixelsToUnits(double px) => unitsPerPixel > 0 ? px * unitsPerPixel : 0;

  double unitsToPixels(double u) => pixelsPerUnit > 0 ? u * pixelsPerUnit : 0;

  @override
  String toString() => 'CalibrationData($realWorldDistance ${unit.symbol} = ${pixelDistance.toStringAsFixed(1)} px)';
}

enum MeasurementUnit {
  meters('m', 'Meters'),
  feet('ft', 'Feet'),
  centimeters('cm', 'Centimeters'),
  inches('in', 'Inches');

  const MeasurementUnit(this.symbol, this.displayName);

  final String symbol;
  final String displayName;

  static MeasurementUnit? fromString(String value) {
    try {
      return MeasurementUnit.values.firstWhere(
        (MeasurementUnit element) => element.name == value,
      );
    } catch (e) {
      return null;
    }
  }

  static MeasurementUnit? fromJson(String value) {
    try {
      return MeasurementUnit.values.firstWhere((MeasurementUnit element) => element.name == value);
    } catch (e) {
      return null;
    }
  }

  String toJson() => name;
}
