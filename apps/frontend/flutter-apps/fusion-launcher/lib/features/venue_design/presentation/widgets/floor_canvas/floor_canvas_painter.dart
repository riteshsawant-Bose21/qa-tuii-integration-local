import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/constants/spl_calculation_data.dart';
import '../../../../../core/models/floor_plan_entity.dart';
import '../../../../../core/models/hardware_component_entity.dart';
import '../../../../../core/models/listening_area_entity.dart';
import '../../../../../core/models/speaker_entity.dart';
import '../../../../../core/models/zone_entity.dart';
import '../../../../../core/utils/fusion_utils.dart';

class FloorCanvasPainter extends CustomPainter {
  static const List<Color> legendColors = <Color>[
    Color(0xFF00008B),
    Color(0xFF007FFF),
    Color(0xFF00FFFF),
    Color(0xFF00FF00),
    Color(0xFFFFFF00),
    Color(0xFFFFA500),
    Color(0xFFFF8C00),
    Color(0xFFFF0000),
    Color(0xFF8B0000),
  ];

  final double gridSize, zoomScale;
  final Offset panOffset;
  final List<Offset> current;
  final Offset? previewPoint;
  final int? highlightedIndex;
  final int? selectedHardwareComponentIndex;
  final bool showSpl;
  final bool floorPlanImageSelected;
  static final Color defaultListeningAreaColor = Colors.blueGrey;
  final double splMin;
  final double splMax;

  final List<ListeningArea> listeningAreas;
  final List<HardwareComponent> hardwareComponents;
  final FloorPlanEntity floorPlanEntity;
  final ui.Image? floorPlanImage;
  Map<String, ui.Image> hardwareImages;
  final bool listeningAreaSelectionActive;
  final List<String> selectedListeningAreaIds;
  final List<Zone> zones;
  Zone? currentlySelectingZone;

  FloorCanvasPainter({
    required this.gridSize,
    required this.zoomScale,
    required this.panOffset,
    required this.listeningAreas,
    required this.zones,
    required this.current,
    required this.showSpl,
    required this.floorPlanImageSelected,
    required this.hardwareComponents,
    required this.floorPlanEntity,
    required this.floorPlanImage,
    required this.hardwareImages,
    required this.listeningAreaSelectionActive,
    required this.selectedListeningAreaIds,
    required this.currentlySelectingZone,
    required this.splMax,
    required this.splMin,
    this.previewPoint,
    this.highlightedIndex,
    this.selectedHardwareComponentIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomScale);

    _drawHeatMap(canvas);
    _drawFloorPlanImage(canvas);
    _drawGrid(canvas, size);
    _drawFloorPlanImageHandles(canvas);
    _drawListeningAreas(canvas);
    _drawHardwareComponents(canvas);
    _drawInProgressPath(canvas);

    canvas.restore();
    // _drawGridLabels(canvas, size);
  }

  /// Todo: optimize grid labels
  void _drawGridLabels(Canvas canvas, Size size) {
    // Text style in screen‐pixels
    final TextStyle textStyle = const TextStyle(color: Colors.black45, fontSize: 12);
    // Compute how the grid was laid out
    final double startX = -panOffset.dx / zoomScale;
    final double startY = -panOffset.dy / zoomScale;
    final int cols = (size.width / zoomScale).ceil() + 2;
    final int rows = (size.height / zoomScale).ceil() + 2;

    // Vertical lines → x-labels along bottom
    for (int i = -1; i < cols; i++) {
      // world-space x of this line
      final double xw = (startX / gridSize).floor() * gridSize + i * gridSize;
      // screen-space x
      final double xs = xw * zoomScale + panOffset.dx;

      // draw the text
      final TextPainter tp = TextPainter(
        text: TextSpan(text: (xw / 100).toStringAsFixed(0), style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      // center it on the line, place at bottom edge
      tp.paint(canvas, Offset(xs - tp.width / 2, size.height - tp.height));
    }

    // Horizontal lines → y-labels along left
    for (int j = -1; j < rows; j++) {
      final double yw = (startY / gridSize).floor() * gridSize + j * gridSize;
      final double ys = yw * zoomScale + panOffset.dy;

      final TextPainter tp = TextPainter(
        text: TextSpan(text: (yw / 100).toStringAsFixed(0), style: textStyle),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      // right-align it at the left edge
      tp.paint(canvas, Offset(0, ys - tp.height / 2));
    }
  }

  void _drawHeatMap(Canvas canvas) {
    if (!showSpl) return;
    final List<HeatMapData> heatMapData = _buildSortedHeatMapEntries();
    final double pointSize = gridSize / 2;

    final ui.Path tmpPath = Path();

    for (final ListeningArea listeningArea in listeningAreas) {
      final SplData? spl = listeningArea.splData;
      if (spl == null) continue;

      // 1) compute clipPath once
      tmpPath.reset();
      tmpPath.addPolygon(listeningArea.vertices, true);
      canvas.save();
      canvas.clipPath(tmpPath);

      // 2) draw *all* points for that listeningArea
      for (final HeatMapData data in heatMapData.where((HeatMapData e) => e.listeningArea == listeningArea)) {
        final double v = data.value.clamp(splMin, splMax);
        final Color color = _colorFromLegend(v);

        final ui.Paint paint =
            Paint()
              ..color = color
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

        canvas.drawRect(
          Rect.fromCenter(
            center: data.point,
            width: pointSize,
            height: pointSize,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  void _drawFloorPlanImage(Canvas canvas) {
    if (floorPlanImage == null) return;

    final ui.Rect src = Rect.fromLTWH(
      0,
      0,
      floorPlanImage!.width.toDouble(),
      floorPlanImage!.height.toDouble(),
    );

    final double h = floorPlanEntity.size.height;
    final double w = floorPlanEntity.size.width;

    final ui.Rect dst = Rect.fromLTWH(
      floorPlanEntity.position.dx,
      floorPlanEntity.position.dy,
      w,
      h,
    );

    // draw base image and inverted-luminance mask
    canvas.saveLayer(dst, Paint());
    canvas.drawImageRect(floorPlanImage!, src, dst, Paint());
    const List<double> invLum = <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, -0.2126, -0.7152, -0.0722, 1, 0];

    Paint floorPlanPaint = Paint();

    if (showSpl) {
      floorPlanPaint =
          Paint()
            ..colorFilter = const ColorFilter.matrix(invLum)
            ..blendMode = BlendMode.dstIn;
    }

    canvas.drawImageRect(
      floorPlanImage!,
      src,
      dst,
      floorPlanPaint,
    );
    canvas.restore();
  }

  void _drawFloorPlanImageHandles(Canvas canvas) {
    if (floorPlanImage == null) return;

    final List<ui.Offset> corners = _computeFloorPlanImageCorners();
    final ui.Paint stroke =
        Paint()
          ..color = Colors.blueGrey
          ..style = PaintingStyle.stroke
          ..strokeWidth = (floorPlanImageSelected ? 2 : 1) / zoomScale;
    // final ui.Paint fill = Paint()..color = Colors.orangeAccent;
    // final double r = 8.0 / zoomScale;

    // outline
    canvas.drawPath(Path()..addPolygon(corners, true), stroke);

    // if (floorPlanImageSelected) {
    //   for (final ui.Offset pt in corners) {
    //     canvas.drawCircle(pt, r, fill);
    //   }
    // }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final ui.Paint pg =
        Paint()
          ..color = Colors.grey.shade300.withValues(alpha: 0.5)
          ..strokeWidth = 1 / zoomScale;
    final double sx = -panOffset.dx / zoomScale, sy = -panOffset.dy / zoomScale;
    final int cols = (size.width / zoomScale).ceil() + 2;
    final int rows = (size.height / zoomScale).ceil() + 2;

    for (int i = -1; i < cols; i++) {
      final double x = (sx / gridSize).floor() * gridSize + i * gridSize;
      canvas.drawLine(Offset(x, sy - gridSize), Offset(x, sy + rows * gridSize), pg);
    }
    for (int j = -1; j < rows; j++) {
      final double y = (sy / gridSize).floor() * gridSize + j * gridSize;
      canvas.drawLine(Offset(sx - gridSize, y), Offset(sx + cols * gridSize, y), pg);
    }
  }

  void _drawListeningAreas(Canvas canvas) {
    for (int i = 0; i < listeningAreas.length; i++) {
      final List<ui.Offset> poly = listeningAreas[i].vertices;
      final ui.Path path = Path()..addPolygon(poly, true);

      bool selected = false;

      late Zone? parentZone;
      try {
        parentZone = zones.firstWhere((Zone z) => z.listeningAreasIds.contains(listeningAreas[i].id));
      } catch (e) {
        parentZone = null;
      }

      Color zoneColor = parentZone != null ? FusionUtils.hexToColor(parentZone.zoneColor) : defaultListeningAreaColor;

      if (listeningAreaSelectionActive) {
        selected = selectedListeningAreaIds.contains(listeningAreas[i].id);
        if (selected && currentlySelectingZone != null) {
          zoneColor = FusionUtils.hexToColor(currentlySelectingZone!.zoneColor);
        } else if (!selected && parentZone == currentlySelectingZone) {
          zoneColor = defaultListeningAreaColor;
        }
      } else {
        selected = i == highlightedIndex;
      }

      final ui.Paint fill =
          Paint()
            ..color = zoneColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;

      final ui.Paint stroke =
          Paint()
            ..color = zoneColor
            ..strokeWidth = 2 / zoomScale
            ..style = PaintingStyle.stroke;

      final ui.Paint fillSelected =
          Paint()
            ..color = zoneColor.withValues(alpha: 0.45)
            ..style = PaintingStyle.fill;

      final ui.Paint strokeSelected =
          Paint()
            ..color = zoneColor
            ..strokeWidth = 2 / zoomScale
            ..style = PaintingStyle.stroke;

      final ui.Paint vertexPaint =
          Paint()
            ..color = zoneColor
            ..style = PaintingStyle.fill;

      final double vertexSize = 4.0 / zoomScale;

      if (!showSpl || hardwareComponents.isEmpty) canvas.drawPath(path, selected ? fillSelected : fill);

      canvas.drawPath(path, selected ? strokeSelected : stroke);
      for (final ui.Offset p in poly) {
        if (selected) {
          canvas.drawCircle(p, vertexSize, vertexPaint);
        }
      }
    }
  }

  void _drawHardwareComponents(Canvas canvas) {
    final double iconSize = ((gridSize / 2.5) / zoomScale).clamp(gridSize * 0.75, gridSize * 1.25);

    for (int i = 0; i < hardwareComponents.length; i++) {
      final HardwareComponent comp = hardwareComponents[i];
      final Rect dst = Rect.fromCenter(
        center: comp.pos,
        width: comp is Speaker ? iconSize / 1.5 : iconSize,
        height: comp is Speaker ? iconSize / 1.5 : iconSize,
      );

      final ui.Image? img = hardwareImages[comp.assetImagePath];
      if (img != null) {
        // draw the loaded image, scaling it into dst
        final ui.Rect src = Rect.fromLTWH(
          0,
          0,
          img.width.toDouble(),
          img.height.toDouble(),
        );
        canvas.drawImageRect(img, src, dst, Paint());
      } else {
        // fallback: draw a grey box until the image is ready
        canvas.drawRect(
          dst,
          Paint()
            ..color = Colors.grey.shade700.withValues(alpha: 0.5)
            ..style = PaintingStyle.fill,
        );
      }

      // draw selection border
      if (i == selectedHardwareComponentIndex) {
        canvas.drawRect(
          Rect.fromCenter(
            center: comp.pos,
            width: gridSize,
            height: gridSize,
          ),
          Paint()
            ..color = Colors.pinkAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 / zoomScale,
        );
      }
    }
  }

  void _drawInProgressPath(Canvas canvas) {
    if (current.isEmpty) return;
    final ui.Path path = Path()..moveTo(current.first.dx, current.first.dy);
    final ui.Paint strSel =
        Paint()
          ..color = defaultListeningAreaColor
          ..strokeWidth = 4 / zoomScale
          ..style = PaintingStyle.stroke;
    final ui.Paint vPaint =
        Paint()
          ..color = defaultListeningAreaColor
          ..style = PaintingStyle.fill;
    final double vSize = 6.0 / zoomScale;

    for (final ui.Offset p in current.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, strSel);
    for (final ui.Offset p in current) {
      canvas.drawCircle(p, vSize, vPaint);
    }
    if (previewPoint != null) {
      canvas.drawLine(current.last, previewPoint!, strSel);
    }
  }

  List<Offset> _computeFloorPlanImageCorners() {
    final ui.Offset p = floorPlanEntity.position;
    final double h = floorPlanEntity.size.height;
    if (floorPlanImage == null) {
      final double w = floorPlanEntity.size.width;
      return <ui.Offset>[p, p + Offset(w, 0), p + Offset(w, h), p + Offset(0, h)];
    }
    final double ar = floorPlanImage!.width / floorPlanImage!.height;
    final double w = h * ar; // preserve aspect ratio
    return <ui.Offset>[
      p,
      p + Offset(w, 0),
      p + Offset(w, h),
      p + Offset(0, h),
    ];
  }

  List<HeatMapData> _buildSortedHeatMapEntries() {
    final List<HeatMapData> entries = <HeatMapData>[];
    for (final ListeningArea s in listeningAreas) {
      final SplData? spl = s.splData;
      if (spl == null) continue;
      final List<ui.Offset> pts = spl.fieldPoints;
      final List<double> vals = spl.splValues;
      if (pts.length != vals.length) continue;
      for (int i = 0; i < pts.length; i++) {
        entries.add(HeatMapData(listeningArea: s, point: pts[i], value: vals[i]));
      }
    }
    entries.sort((HeatMapData a, HeatMapData b) => a.value.compareTo(b.value));
    return entries;
  }

  Color _colorFromLegend(double v) {
    final double c = v.clamp(splMin, splMax);
    final double t = (c - splMin) / (splMax - splMin);
    final int n = SPLCalculationData.legendColors.length;
    final double idx = t * (n - 1);
    final int i0 = idx.floor().clamp(0, n - 1);
    final int i1 = idx.ceil().clamp(0, n - 1);
    final double f = idx - i0;
    return Color.lerp(SPLCalculationData.legendColors[i0], SPLCalculationData.legendColors[i1], f)!;
  }

  @override
  bool shouldRepaint(covariant FloorCanvasPainter old) {
    return old.gridSize != gridSize ||
        old.zoomScale != zoomScale ||
        old.panOffset != panOffset ||
        old.listeningAreas != listeningAreas ||
        old.current != current ||
        old.previewPoint != previewPoint ||
        old.highlightedIndex != highlightedIndex ||
        old.floorPlanEntity != floorPlanEntity ||
        old.floorPlanImageSelected != floorPlanImageSelected ||
        old.showSpl != showSpl ||
        old.hardwareComponents != hardwareComponents ||
        old.hardwareImages != hardwareImages ||
        old.selectedHardwareComponentIndex != selectedHardwareComponentIndex;
  }
}

class HeatMapData {
  final ListeningArea listeningArea;
  final Offset point;
  final double value;

  HeatMapData({
    required this.listeningArea,
    required this.point,
    required this.value,
  });
}
