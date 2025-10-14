import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/strings/fusion_strings.dart';

import '../fusion_widgets/buttons/fusion_text_button.dart';

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
    return DecoratedBox(
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
          child: FloorPlanCalibrator(
            floorPlanImage: floorPlanImage,
            onCalibrationComplete: onCalibrationComplete,
            onCancel: onCancel,
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
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Close',
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                splashRadius: 18,
                onPressed: onClose,
              ),
            ],
          ),
        ),
        // The calibrator will render its own toolbar row + canvas + footer
        Expanded(child: child),
      ],
    );
  }
}

enum _ToolMode { measure, crop }

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
  // --- measurement state ---
  Offset? _startPointNormalized;
  Offset? _endPointNormalized;
  Offset? _startPointDisplay;
  Offset? _endPointDisplay;
  bool _isDrawing = false;

  // --- crop state (normalized to the displayed image rect 0..1) ---
  Rect _cropRectN = const Rect.fromLTWH(0, 0, 1, 1);
  _CropHandle _activeHandle = _CropHandle.none;

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
    final x = ((p.dx - r.left) / r.width).clamp(0.0, 1.0);
    final y = ((p.dy - r.top) / r.height).clamp(0.0, 1.0);
    return Offset(x, y);
  }

  Offset? _normalizedToScreen(Offset n) {
    final r = _imageRect;
    if (r == null) return null;
    return Offset(r.left + n.dx * r.width, r.top + n.dy * r.height);
  }

  Offset _normalizedToImagePx(Offset n) => Offset(n.dx * widget.floorPlanImage.width, n.dy * widget.floorPlanImage.height);

  // ---------- measure interactions ----------
  void _onMeasureTapDown(TapDownDetails d) {
    final n = _screenToNormalized(d.localPosition);
    if (n == null) return;

    if (_startPointNormalized == null || !_isDrawing) {
      setState(() {
        _startPointNormalized = n;
        _startPointDisplay = d.localPosition;
        _endPointNormalized = null;
        _endPointDisplay = null;
        _isDrawing = true;
      });
    } else {
      setState(() {
        _endPointNormalized = n;
        _endPointDisplay = d.localPosition;
        _isDrawing = false;
      });
    }
  }

  void _onMeasurePanUpdate(DragUpdateDetails d) {
    if (!_isDrawing || _startPointNormalized == null) return;
    final n = _screenToNormalized(d.localPosition);
    if (n == null) return;
    setState(() {
      _endPointNormalized = n;
      _endPointDisplay = d.localPosition;
    });
  }

  void _onMeasureHover(PointerHoverEvent e) {
    if (!_isDrawing || _startPointNormalized == null) return;
    final n = _screenToNormalized(e.localPosition);
    if (n == null) return;
    setState(() {
      _endPointNormalized = n;
      _endPointDisplay = e.localPosition;
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

    // Convert screen position to normalized coordinates relative to image
    final normalizedX = ((screenPos.dx - r.left) / r.width).clamp(0.0, 1.0);
    final normalizedY = ((screenPos.dy - r.top) / r.height).clamp(0.0, 1.0);
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
      _CropHandle.topLeft: Offset(crop.left, crop.top),
      _CropHandle.top: Offset(centerX, crop.top),
      _CropHandle.topRight: Offset(crop.right, crop.top),
      _CropHandle.right: Offset(crop.right, centerY),
      _CropHandle.bottomRight: Offset(crop.right, crop.bottom),
      _CropHandle.bottom: Offset(centerX, crop.bottom),
      _CropHandle.bottomLeft: Offset(crop.left, crop.bottom),
      _CropHandle.left: Offset(crop.left, centerY),
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
  }

  // ---------- image cropping ----------
  Future<ui.Image?> _getCroppedImage() async {
    final image = widget.floorPlanImage;

    // Convert normalized crop rect to actual pixel coordinates
    final cropRect = Rect.fromLTRB(
      (_cropRectN.left * image.width).round().toDouble(),
      (_cropRectN.top * image.height).round().toDouble(),
      (_cropRectN.right * image.width).round().toDouble(),
      (_cropRectN.bottom * image.height).round().toDouble(),
    );

    // Ensure crop rect is within image bounds
    final clampedRect = Rect.fromLTRB(
      cropRect.left.clamp(0.0, image.width.toDouble()),
      cropRect.top.clamp(0.0, image.height.toDouble()),
      cropRect.right.clamp(0.0, image.width.toDouble()),
      cropRect.bottom.clamp(0.0, image.height.toDouble()),
    );

    // If crop rect is the full image, return the original
    if (clampedRect.left <= 0 && clampedRect.top <= 0 && clampedRect.right >= image.width && clampedRect.bottom >= image.height) {
      return image;
    }

    try {
      // Create a picture recorder to draw the cropped portion
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the cropped portion of the image
      canvas.drawImageRect(
        image,
        clampedRect,
        Rect.fromLTWH(0, 0, clampedRect.width, clampedRect.height),
        Paint(),
      );

      final picture = recorder.endRecording();
      return await picture.toImage(
        clampedRect.width.round(),
        clampedRect.height.round(),
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
  }

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
            Text(
              'Invalid image',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Image dimensions: ${widget.floorPlanImage.width}×${widget.floorPlanImage.height}',
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
            children: <Widget>[
              // Left: tool icons
              _ToolbarIcon(
                icon: Icons.edit,
                tooltip: 'Measure scale (draw line)',
                active: _mode == _ToolMode.measure,
                onTap: () => setState(() => _mode = _ToolMode.measure),
              ),
              const SizedBox(width: 8),
              _ToolbarIcon(
                icon: Icons.crop,
                tooltip: 'Crop',
                active: _mode == _ToolMode.crop,
                onTap: () => setState(() => _mode = _ToolMode.crop),
              ),
              const SizedBox(width: 8),
              _ToolbarIcon(
                icon: Icons.center_focus_strong,
                tooltip: 'Fit to screen',
                onTap: _fitToScreen,
              ),
              // const SizedBox(width: 8),
              // _ToolbarIcon(
              //   icon: Icons.open_in_full,
              //   tooltip: 'Full screen',
              //   onTap: () {}, // hook up if you add a full-screen route
              // ),
              const Spacer(),
              // Right: distance + units controls
              Text(
                'Distance',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 96,
                child: TextField(
                  controller: _distanceController,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    hintText: '1.00',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Units',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                child: FusionDropdownButtonFormField(
                  value: '${_selectedUnit.displayName} (${_selectedUnit.symbol})',
                  options: MeasurementUnit.values.map((u) => '${u.displayName} (${u.symbol})').toList(),
                  isDense: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  onChanged: (String? value) {
                    if (value != null) {
                      final selectedUnit = MeasurementUnit.values.firstWhere(
                        (u) => '${u.displayName} (${u.symbol})' == value,
                      );
                      setState(() => _selectedUnit = selectedUnit);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Canvas
        Expanded(
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                child: Center(
                  child: SemanticHelper.container(
                    testId: SemanticHelper.createTestId(SemanticTypes.container, "Floor Plan Calibration"),
                    child: CustomPaint(
                      painter: FloorPlanCalibrationPainter(
                        image: widget.floorPlanImage,
                        startPoint: _startPointDisplay,
                        endPoint: _endPointDisplay,
                        distanceText: _distanceController.text.trim(),
                        unit: _selectedUnit,
                        cropRectNormalized: _cropRectN,
                        showCropHandles: _mode == _ToolMode.crop,
                        onImageRectChanged: (ui.Rect r) {
                          _imageRect = r;
                          // keep display points in sync if image rect changes
                          if (_startPointNormalized != null) {
                            _startPointDisplay = _normalizedToScreen(_startPointNormalized!);
                          }
                          if (_endPointNormalized != null) {
                            _endPointDisplay = _normalizedToScreen(_endPointNormalized!);
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
              // Optional quick actions on the left
              if (_startPointNormalized != null || _endPointNormalized != null)
                FusionTextButton(
                  label: 'Clear Line',
                  width: 120,
                  onTap: () {
                    _clearMeasurement();
                  },
                ),
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
              FusionButton(
                label: FusionStrings.confirmButton,
                width: 120,
                height: 36,
                onTap: () {
                  if (_startPointNormalized != null && _endPointNormalized != null && _distanceController.text.trim().isNotEmpty) {
                    _completeCalibration();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  const _ToolbarIcon({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
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
  final Function(Rect)? onImageRectChanged;

  FloorPlanCalibrationPainter({
    required this.image,
    this.startPoint,
    this.endPoint,
    this.distanceText = '',
    required this.unit,
    this.cropRectNormalized,
    this.showCropHandles = false,
    this.onImageRectChanged,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (image.width <= 0 || image.height <= 0) return;

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

    // draw image
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint()..filterQuality = FilterQuality.high,
    );

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
        Paint()..color = Colors.black.withValues(alpha: 0.25),
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
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final guide = Paint()
        ..color = Colors.white
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke;

      // draw white guide underlay for contrast
      canvas.drawLine(p1, p2, guide);
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
      old.showCropHandles != showCropHandles;
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
}
