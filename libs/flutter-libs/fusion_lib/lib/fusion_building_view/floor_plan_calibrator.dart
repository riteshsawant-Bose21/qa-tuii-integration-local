import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/strings/fusion_strings.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/test_keys.dart';
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _FloorPlanShell(
            title: title,
            onClose: onCancel,
            child: SemanticHelper.container(
              testId: SemanticHelper.createTestId(SemanticTypes.container, "floor_plan_calibrator"),
              child: FloorPlanCalibrator(
                floorPlanImage: floorPlanImage,
                onCalibrationComplete: onCalibrationComplete,
                onCancel: onCancel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple shell to mimic the modal chrome in the reference:
/// Title bar, toolbar row, content, and bottom action bar.
class _FloorPlanShell extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;

  const _FloorPlanShell({
    required this.title,
    required this.child,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Title bar
        SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, "floor_plan_calibrator_title_bar"),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
            ),
            child: Row(
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
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
          ),
        ),
        // The calibrator will render its own toolbar row + canvas + footer
        Expanded(child: child),
      ],
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
  // --- image transform state ---
  bool _flipHorizontal = false;
  bool _flipVertical = false;
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

  // --- crop state (normalized to the displayed image rect 0..1) ---
  Rect _cropRectN = const Rect.fromLTWH(0, 0, 1, 1);
  _CropHandle _activeHandle = _CropHandle.none;

  // --- zoom/pan state ---
  Offset _panZoomStartPan = Offset.zero;
  Offset _panZoomStartFocal = Offset.zero;
  double _panZoomStartScale = 1.0;
  bool _isMiddleMousePanning = false;
  Offset _middleMousePanStart = Offset.zero;
  Offset _middleMousePanOffset = Offset.zero;

  // --- UI/controls ---
  final TextEditingController _distanceController = TextEditingController(text: '5.00');
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

  Offset _normalizedToImagePx(Offset n) => Offset(n.dx * widget.floorPlanImage.width, n.dy * widget.floorPlanImage.height);

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
      fusionLibLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.showFloorPickCalibration);
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

    // Convert screen position to normalized coordinates relative to image
    final normalizedX = ((local.dx - r.left) / r.width).clamp(0.0, 1.0);
    final normalizedY = ((local.dy - r.top) / r.height).clamp(0.0, 1.0);
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

    setState(() => _cropRectN = newN);
  }

  void _onCropPanEnd(DragEndDetails d) {
    _activeHandle = _CropHandle.none;
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

    return <_CropHandle, Offset>{
      _CropHandle.topLeft: _canvasToScreen(Offset(crop.left, crop.top)),
      _CropHandle.top: _canvasToScreen(Offset(centerX, crop.top)),
      _CropHandle.topRight: _canvasToScreen(Offset(crop.right, crop.top)),
      _CropHandle.right: _canvasToScreen(Offset(crop.right, centerY)),
      _CropHandle.bottomRight: _canvasToScreen(Offset(crop.right, crop.bottom)),
      _CropHandle.bottom: _canvasToScreen(Offset(centerX, crop.bottom)),
      _CropHandle.bottomLeft: _canvasToScreen(Offset(crop.left, crop.bottom)),
      _CropHandle.left: _canvasToScreen(Offset(crop.left, centerY)),
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
    setState(() => _cropRectN = const Rect.fromLTWH(0, 0, 1, 1));
  }

  void _fitToScreen() {
    // our painter always fits; this is a placeholder to match the UI
    // you could also reset crop + measurement.
    _resetCrop();
    _clearMeasurement();
    setState(() {
      _zoomScale = 1.0;
      _panOffset = Offset.zero;
      _flipHorizontal = false;
      _flipVertical = false;
    });
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
    ui.Image sourceImage = widget.floorPlanImage;

    // First apply flips to the full image if needed
    if (_flipHorizontal || _flipVertical) {
      try {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final fullWidth = sourceImage.width.toDouble();
        final fullHeight = sourceImage.height.toDouble();

        // Set up flip transformation
        canvas.save();
        canvas.translate(fullWidth / 2, fullHeight / 2);
        canvas.scale(_flipHorizontal ? -1.0 : 1.0, _flipVertical ? -1.0 : 1.0);
        canvas.translate(-fullWidth / 2, -fullHeight / 2);

        // Draw the flipped image
        canvas.drawImage(sourceImage, Offset.zero, Paint());
        canvas.restore();

        final picture = recorder.endRecording();
        sourceImage = await picture.toImage(
          sourceImage.width,
          sourceImage.height,
        );
      } catch (e) {
        // If flip fails, continue with original image
      }
    }

    // Now apply cropping to the (potentially flipped) image
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

    // If no cropping needed, return the (potentially flipped) full image
    if (clampedRect.left <= 0 && clampedRect.top <= 0 && clampedRect.right >= sourceImage.width && clampedRect.bottom >= sourceImage.height) {
      return sourceImage;
    }

    try {
      // Create a picture recorder to draw the cropped portion
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final outputWidth = clampedRect.width;
      final outputHeight = clampedRect.height;

      // Draw the cropped portion of the (flipped) image
      canvas.drawImageRect(
        sourceImage,
        clampedRect,
        Rect.fromLTWH(0, 0, outputWidth, outputHeight),
        Paint(),
      );

      final picture = recorder.endRecording();
      return await picture.toImage(
        outputWidth.round(),
        outputHeight.round(),
      );
    } catch (e) {
      // If cropping fails, return null
      return null;
    }
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
        widget.floorPlanImage.width.toDouble(),
        widget.floorPlanImage.height.toDouble(),
      ),
      croppedImage: croppedImage,
    );
    widget.onCalibrationComplete(data);

    // ignore: use_build_context_synchronously
    fusionLibLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.confirmFloorCalibrated);
  }

  final GlobalKey _customPaintKey = GlobalKey();

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final imageInvalid = widget.floorPlanImage.width <= 0 || widget.floorPlanImage.height <= 0;

    if (imageInvalid) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
              text: 'Image dimensions: ${widget.floorPlanImage.width}×${widget.floorPlanImage.height}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            FusionOutlinedButton(
              label: 'Close',
              onTap: () => widget.onCancel?.call(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        // Toolbar row
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
          ),
          child: Row(
            spacing: 8,
            children: <Widget>[
              // Left: tool icons
              _ToolbarIcon(
                icon: LucideIcons.rulerDimensionLine200,
                seemanticKey: FusionTestKeys.measureScale,
                tooltip: 'Measure scale (draw line)',
                active: _mode == _ToolMode.measure,
                onTap: () => setState(() => _mode = _ToolMode.measure),
              ),
              _ToolbarIcon(
                icon: LucideIcons.crop200,
                seemanticKey: FusionTestKeys.cropImage,
                tooltip: 'Crop',
                active: _mode == _ToolMode.crop,
                onTap: () => setState(() => _mode = _ToolMode.crop),
              ),
              _ToolbarIcon(
                icon: LucideIcons.rotateCcw200,
                seemanticKey: FusionTestKeys.rotateImage,
                tooltip: 'Rotate',
                active: _mode == _ToolMode.rotate,
                onTap: () => setState(() => _mode = _ToolMode.rotate),
              ),
              _ToolbarIcon(
                icon: LucideIcons.flipHorizontal2200,
                seemanticKey: FusionTestKeys.flipHorizontal,
                tooltip: 'Flip Horizontal',
                active: _flipHorizontal,
                onTap: () => setState(() => _flipHorizontal = !_flipHorizontal),
              ),
              _ToolbarIcon(
                icon: LucideIcons.flipVertical2200,
                seemanticKey: FusionTestKeys.flipVertical,
                tooltip: 'Flip Vertical',
                active: _flipVertical,
                onTap: () => setState(() => _flipVertical = !_flipVertical),
              ),
              _ToolbarIcon(
                svgIcon: "packages/fusion_lib/lib/assets/svgs/skew.svg",
                seemanticKey: FusionTestKeys.skew,
                tooltip: 'Skew',
                active: _mode == _ToolMode.skew,
                onTap: () => setState(() => _mode = _ToolMode.skew),
              ),
              _ToolbarIcon(
                svgIcon: "packages/fusion_lib/lib/assets/svgs/reset.svg",
                seemanticKey: FusionTestKeys.reset,
                tooltip: 'Reset',
                enabled: _startPointNormalized != null || _endPointNormalized != null,
                onTap: () {
                  if (_startPointNormalized != null || _endPointNormalized != null) {
                    _clearMeasurement();
                  }
                },
              ),
              _ToolbarIcon(
                seemanticKey: FusionTestKeys.fitToScreen,
                icon: LucideIcons.expand200,
                tooltip: 'Fit to screen',
                onTap: () => _fitToScreen(),
              ),
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
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: MouseRegion(
                cursor: _mode == _ToolMode.measure ? SystemMouseCursors.precise : SystemMouseCursors.resizeUpLeftDownRight,
                onHover: _mode == _ToolMode.measure ? _onMeasureHover : null,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _mode == _ToolMode.measure ? _onMeasureTapDown : null,
                  onPanUpdate: _mode == _ToolMode.measure ? _onMeasurePanUpdate : _onCropPanUpdate,
                  onPanStart: _mode == _ToolMode.crop ? _onCropPanStart : null,
                  onPanEnd: (d) {
                    if (_mode == _ToolMode.crop) _onCropPanEnd(d);
                    if (_mode == _ToolMode.measure && _isDrawing) {
                      setState(() => _isDrawing = false);
                    }
                  },
                  child: GuideShowcaseWrapper(
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
                            image: widget.floorPlanImage,
                            startPoint: _startPointDisplay,
                            endPoint: _endPointDisplay,
                            distanceText: _distanceController.text.trim(),
                            unit: _selectedUnit,
                            cropRectNormalized: _cropRectN,
                            showCropHandles: _mode == _ToolMode.crop,
                            zoomScale: _zoomScale,
                            panOffset: _panOffset,
                            flipHorizontal: _flipHorizontal,
                            flipVertical: _flipVertical,
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

        // Footer buttons (right aligned)
        Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: <Widget>[
              const Spacer(),
              FusionOutlinedButton(
                width: 120,
                height: 36,
                label: FusionStrings.cancelButton,
                onTap: () {
                  widget.onCancel!();
                },
              ),
              const SizedBox(width: 8),
              GuideShowcaseWrapper(
                step: GuideShowCaseSteps.confirmFloorCalibrated,
                onHighlightedSpotTap: (TapDownDetails details) {
                  if (_startPointNormalized != null && _endPointNormalized != null && _distanceController.text.trim().isNotEmpty) {
                    _completeCalibration();
                  }
                },
                child: FusionButton(
                  label: FusionStrings.confirmButton,
                  width: 120,
                  height: 36,
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
                color: active ? context.colorScheme.elevation3 : null,
                border: Border.all(
                  color: context.colorScheme.outline.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FittedBox(
                child: Builder(
                  builder: (context) {
                    if (svgIcon != null) {
                      return FusionSvgIcon(
                        icon: svgIcon!,
                        color: active ? context.colorScheme.primaryWhite : context.colorScheme.iconDefault,
                      );
                    }
                    return Icon(
                      icon,
                      size: 16,
                      color: active ? context.colorScheme.primaryWhite : context.colorScheme.iconDefault,
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

class FloorPlanCalibrationPainter extends CustomPainter {
  final ui.Image image;
  final Offset? startPoint;
  final Offset? endPoint;
  final String distanceText;
  final MeasurementUnit unit;
  final Rect? cropRectNormalized; // 0..1 inside the displayed image rect
  final bool showCropHandles;
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

    // Flip transform
    if (flipHorizontal || flipVertical) {
      canvas.save();
      // Center of imageRect
      final cx = imageRect.left + imageRect.width / 2;
      final cy = imageRect.top + imageRect.height / 2;
      canvas.translate(cx, cy);
      canvas.scale(flipHorizontal ? -1.0 : 1.0, flipVertical ? -1.0 : 1.0);
      canvas.translate(-cx, -cy);
    }

    // draw image
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint()..filterQuality = FilterQuality.high,
    );

    if (flipHorizontal || flipVertical) {
      canvas.restore();
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

      // darken outside
      final Path outside = Path()..addRect(Offset.zero & size);
      final Path hole = Path()..addRect(crop);
      final Path overlay = Path.combine(PathOperation.difference, outside, hole);
      canvas.drawPath(
        overlay,
        Paint()..color = Colors.white,
      );

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

        const double s = 12;
        final Paint hp = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final Paint hb = Paint()
          ..color = Colors.black
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

        for (final p in pts.values) {
          final r = Rect.fromCenter(center: p, width: s, height: s);
          canvas.drawRect(r, hp);
          canvas.drawRect(r, hb);
        }
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
      final Offset labPos = Offset(mid.dx - tp.width / 2, mid.dy - 28 - tp.height / 2);
      final RRect bg = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labPos.dx - pad,
          labPos.dy - pad,
          tp.width + pad * 2,
          tp.height + pad * 2,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(bg, Paint()..color = Colors.black.withValues(alpha: 0.8));
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
    Offset rot(double a) => Offset(ux * math.cos(a) - uy * math.sin(a), ux * math.sin(a) + uy * math.cos(a));

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
      return MeasurementUnit.values.firstWhere((MeasurementUnit element) => element.name == value);
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
