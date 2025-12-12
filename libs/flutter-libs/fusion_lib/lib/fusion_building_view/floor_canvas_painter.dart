import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_utils/color_utils.dart';

import '../fusion_acoustic_calculation_engine/spl_calculation_data.dart';

class FloorCanvasPainter extends CustomPainter {
  final double gridSize, zoomScale;
  final Offset panOffset;
  final List<Offset> current;
  final Offset? previewPoint;
  final int? highlightedIndex;
  final String? selectedHardwareComponentId;
  final bool showSpl;
  final bool floorPlanImageSelected;
  static final Color defaultListeningAreaColor = ColorUtils.hexToColor("#747474");
  final double splMin;
  final double splMax;

  final List<ListeningArea> listeningAreas;
  final List<HardwareComponent> hardwareComponents;
  final FloorPlanModel floorPlanEntity;
  final ui.Image? floorPlanImage;
  Map<String, ui.Image> hardwareImages;
  final bool listeningAreaSelectionActive;
  final List<String> selectedListeningAreaIds;
  final List<Zone> zones;
  final List<SubZone> subZones;
  Zone? currentlySelectingZone;
  SubZone? currentlySelectingSubZone;
  final SplPanelData splPanelData;

  //key value pair for listening area and its zone
  final Map<String, String> listeningAreaToZoneMap;
  final Map<String, String> subZoneToZoneMap;
  final Map<String, String> listeningAreaToSubZoneMap;

  // Mode state
  final bool isAcousticsMode;

  FloorCanvasPainter({
    required this.gridSize,
    required this.zoomScale,
    required this.panOffset,
    required this.listeningAreas,
    required this.zones,
    required this.subZones,
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
    required this.currentlySelectingSubZone,
    required this.splMax,
    required this.splMin,
    required this.isAcousticsMode,
    this.previewPoint,
    this.highlightedIndex,
    this.selectedHardwareComponentId,
    required this.splPanelData,
    required this.listeningAreaToZoneMap,
    required this.listeningAreaToSubZoneMap,
    required this.subZoneToZoneMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomScale);

    if (showSpl) {
      _drawGrid(canvas, size);
      _drawHeatMap(canvas);
      _drawFloorPlanImage(canvas);
    } else {
      _drawFloorPlanImage(canvas);
      _drawGrid(canvas, size);
    }

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

        final ui.Paint paint = Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

        canvas.drawRect(Rect.fromCenter(center: data.point, width: pointSize, height: pointSize), paint);
      }
      canvas.restore();
    }
  }

  void _drawFloorPlanImage(Canvas canvas) {
    if (floorPlanImage == null) return;

    final ui.Rect src = Rect.fromLTWH(0, 0, floorPlanImage!.width.toDouble(), floorPlanImage!.height.toDouble());

    final double h = floorPlanEntity.size.height;
    final double w = floorPlanEntity.size.width;

    final ui.Rect dst = Rect.fromLTWH(floorPlanEntity.position.dx, floorPlanEntity.position.dy, w, h);

    // draw base image and inverted-luminance mask
    canvas.saveLayer(dst, Paint());
    canvas.drawImageRect(floorPlanImage!, src, dst, Paint());

    const List<double> invLum = <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, -0.2126, -0.7152, -0.0722, 1, 0];
    Paint floorPlanPaint = Paint();

    if (showSpl) {
      floorPlanPaint = Paint()
        ..colorFilter = const ColorFilter.matrix(invLum)
        ..blendMode = BlendMode.dstIn;
    }

    canvas.drawImageRect(floorPlanImage!, src, dst, floorPlanPaint);
    canvas.restore();
  }

  void _drawFloorPlanImageHandles(Canvas canvas) {
    if (floorPlanImage == null) return;

    final List<ui.Offset> corners = _computeFloorPlanImageCorners();
    final ui.Paint stroke = Paint()
      ..color = Colors.blueGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = (floorPlanImageSelected ? 2 : 1) / zoomScale;
    // final ui.Paint fill = Paint()..color = Colors.orangeAccent;
    // final double r = 8.0 / zoomScale;

    // outline
    // canvas.drawPath(Path()..addPolygon(corners, true), stroke);

    // if (floorPlanImageSelected) {
    //   for (final ui.Offset pt in corners) {
    //     canvas.drawCircle(pt, r, fill);
    //   }
    // }
  }

  void _drawGrid(Canvas canvas, Size size) {
    const double dotRadius = 10;

    final Paint paint = Paint()
      ..color = Colors.grey.shade300.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Find visible bounds in world coordinates
    final double left = -panOffset.dx / zoomScale;
    final double top = -panOffset.dy / zoomScale;
    final double right = left + size.width / zoomScale;
    final double bottom = top + size.height / zoomScale;

    // Snap to grid so it always looks infinite
    final double spacing = gridSize;
    final double startX = (left ~/ spacing) * spacing;
    final double startY = (top ~/ spacing) * spacing;

    for (double x = startX; x < right; x += spacing) {
      for (double y = startY; y < bottom; y += spacing) {
        final double r = (dotRadius / zoomScale).clamp(6.0, 8.0); // clamp to avoid oversized dots
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  /// Draw all listening areas on the canvas
  void _drawListeningAreas(Canvas canvas) {
    for (int i = 0; i < listeningAreas.length; i++) {
      final List<ui.Offset> poly = listeningAreas[i].vertices;
      final ui.Path path = Path()..addPolygon(poly, true);

      bool selected = false;

      // Determine if listening area belongs to a subzone or zone
      SubZone? parentSubZone;
      Zone? parentZone;

      final String? subZoneId = listeningAreaToSubZoneMap[listeningAreas[i].id];
      if (subZoneId != null) {
        // Listening area belongs to a subzone
        try {
          parentSubZone = subZones.firstWhere((SubZone sz) => sz.id == subZoneId);
          // Get the parent zone for color
          final String? zoneId = subZoneToZoneMap[subZoneId];
          if (zoneId != null) {
            parentZone = zones.firstWhere((Zone z) => z.id == zoneId);
          }
        } catch (e) {
          parentSubZone = null;
          parentZone = null;
        }
      } else {
        // Listening area belongs directly to a zone
        final String? zoneId = listeningAreaToZoneMap[listeningAreas[i].id];
        if (zoneId != null) {
          try {
            parentZone = zones.firstWhere((Zone z) => z.id == zoneId);
          } catch (e) {
            parentZone = null;
          }
        }
      }

      Color zoneColor = parentZone != null ? ColorUtils.hexToColor(parentZone.zoneColor) : defaultListeningAreaColor;

      if (listeningAreaSelectionActive) {
        selected = selectedListeningAreaIds.contains(listeningAreas[i].id);
        if (selected && currentlySelectingZone != null) {
          zoneColor = ColorUtils.hexToColor(currentlySelectingZone!.zoneColor);
        } else if (!selected && parentZone == currentlySelectingZone) {
          zoneColor = defaultListeningAreaColor;
        }
      } else {
        selected = i == highlightedIndex;
      }

      final ui.Paint fill = Paint()
        ..color = zoneColor.withValues(alpha: 0.30)
        ..style = PaintingStyle.fill;

      final ui.Paint stroke = Paint()
        ..color = zoneColor
        ..strokeWidth = 2 / zoomScale
        ..style = PaintingStyle.stroke;

      final ui.Paint fillSelected = Paint()
        ..color = zoneColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;

      final ui.Paint strokeSelected = Paint()
        ..color = zoneColor
        ..strokeWidth = 2 / zoomScale
        ..style = PaintingStyle.stroke;

      final ui.Paint vertexPaint = Paint()
        ..color = zoneColor
        ..style = PaintingStyle.fill;

      final double vertexSize = 4.0 / zoomScale;

      if (!showSpl || hardwareComponents.isEmpty) {
        canvas.drawPath(path, selected ? fillSelected : fill);
      }
      canvas.drawPath(path, selected ? strokeSelected : stroke);

      for (final ui.Offset p in poly) {
        if (selected && isAcousticsMode) {
          canvas.drawCircle(p, vertexSize, vertexPaint);
        }
      }

      final anchor = _leftMostVertex(poly, zoomScale);
      String label = listeningAreas[i].name ?? 'Area ${i + 1}';

      // Add zone/subzone information to the label
      if (parentSubZone != null) {
        // Listening area belongs to a subzone
        label = '$label (${parentSubZone.name})';
      } else if (parentZone != null) {
        // Listening area belongs directly to a zone
        label = '$label (${parentZone.name})';
      }

      _drawBadgeAtLeftMostVertexAuto(
        canvas: canvas,
        path: path,
        anchor: anchor,
        label: label,
        background: zoneColor,
        zoomScale: zoomScale,
      );
    }
  }

  Offset _leftMostVertex(List<Offset> poly, double zoomScale) {
    const double baseTol = 0.5; // px
    final double tol = baseTol / zoomScale;
    Offset best = poly.first;
    for (final p in poly) {
      final bool moreLeft = p.dx < best.dx - tol;
      final bool sameXHigher = (p.dx - best.dx).abs() <= tol && p.dy < best.dy;
      if (moreLeft || sameXHigher) best = p;
    }
    return best;
  }

  // Returns vertical inside span at x as Offset(top, bottom); null if no span.
  Offset? _verticalSpanAtX({
    required Path path,
    required double x,
    required Rect bounds,
    required double stepY,
  }) {
    bool inside = false;
    double? start;
    for (double y = bounds.top + stepY; y <= bounds.bottom - stepY; y += stepY) {
      final hit = path.contains(Offset(x, y));
      if (hit && !inside) {
        inside = true;
        start = y;
      } else if (!hit && inside) {
        return Offset(start!, y - stepY);
      }
    }
    if (inside && start != null) return Offset(start!, bounds.bottom - stepY);
    return null;
  }

  void _drawBadgeAtLeftMostVertexAuto({
    required Canvas canvas,
    required Path path,
    required Offset anchor, // left-most vertex
    required String label,
    required Color background,
    required double zoomScale,
  }) {
    final double zs = (zoomScale <= 0.35) ? 0.35 : zoomScale;

    // UI sizing (zoom-invariant)
    final double fontSize = 11.0 / zs;
    final double padH = 8.0 / zs;
    final double padV = 4.0 / zs;
    final double radius = 4.0 / zs;
    final double margin = 6.0 / zs;

    final Rect bounds = path.getBounds();

    // Width capped by space to the RIGHT of the left-most vertex
    final double maxBadgeWidth = (bounds.right - anchor.dx - 2 * margin).clamp(40.0 / zs, 220.0 / zs);

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxBadgeWidth);

    final Size badgeSize = Size(tp.width + padH * 2, tp.height + padV * 2);

    // Left-align to the vertex, nudge inside by margin
    double rectLeft = anchor.dx + margin;
    // Keep inside overall bounds horizontally
    final double maxLeft = bounds.right - margin - badgeSize.width;
    if (rectLeft > maxLeft) rectLeft = maxLeft;

    // Compute vertical span of the shape at badge center X
    final double sampleX = rectLeft + badgeSize.width / 2;
    final Offset? span = _verticalSpanAtX(
      path: path,
      x: sampleX,
      bounds: bounds,
      stepY: (2.0 / zs).clamp(0.5, 6.0),
    );

    // Start centered on anchor; then clamp inside the span (auto top/bottom)
    double top = anchor.dy - badgeSize.height / 2;

    if (span != null) {
      final double minTop = span.dx + margin;
      final double maxTop = span.dy - badgeSize.height - margin;

      if (maxTop < minTop) {
        // Span shorter than badge height: pin to span top (best effort)
        top = minTop;
      } else {
        top = top.clamp(minTop, maxTop);
      }
    } else {
      // Fallback to polygon bounds (rare)
      final double minTop = bounds.top + margin;
      final double maxTop = bounds.bottom - badgeSize.height - margin;
      if (maxTop < minTop) {
        top = bounds.top + (bounds.height - badgeSize.height) / 2;
      } else {
        top = top.clamp(minTop, maxTop);
      }
    }

    final Rect rect = Rect.fromLTWH(rectLeft, top, badgeSize.width, badgeSize.height);
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Background pill + text
    canvas.drawRRect(rrect, Paint()..color = background.withOpacity(0.92));
    tp.paint(canvas, Offset(rect.left + padH, rect.top + padV));
  }

  /// Draw all hardware components (speakers, etc.) on the canvas
  void _drawHardwareComponents(Canvas canvas) {
    final double iconSize = ((gridSize / 2.5) / zoomScale).clamp(gridSize * 0.5, gridSize * 1.0);

    for (int i = 0; i < hardwareComponents.length; i++) {
      final HardwareComponent comp = hardwareComponents[i];

      // In acoustics mode, only draw speakers and skip other hardware components
      if (isAcousticsMode && comp is! Speaker) {
        continue;
      }

      final Rect dst = Rect.fromCenter(
        center: comp.pos,
        width: comp is SpeakerModel ? iconSize / 1.5 : iconSize,
        height: comp is SpeakerModel ? iconSize / 1.5 : iconSize,
      );

      if (comp is Speaker) {
        final double radius = (dst.width / 2) * 0.5;
        final SpeakerModel? speakerModel = SpeakerCatalog.findByModel(comp.speakerSKU);

        if (speakerModel != null) {
          final Paint fillPaint = Paint()
            ..color = Colors.black
            ..style = PaintingStyle.fill;

          final Paint outlinePaint = Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 / zoomScale;

          // --- SURFACE-MOUNTED (Rectangle) ---
          if (speakerModel.mountingType == 'surface') {
            final Rect rect = Rect.fromCenter(
              center: comp.pos,
              width: radius * 1.5,
              height: radius * 2,
            );
            canvas.drawRect(rect, fillPaint);
            canvas.drawRect(rect, outlinePaint);
          }
          // --- PENDANT (Triangle) ---
          else if (speakerModel.mountingType == 'pendant') {
            final Path path = Path()
              ..moveTo(comp.pos.dx, comp.pos.dy - radius)
              ..lineTo(comp.pos.dx - radius * 0.866, comp.pos.dy + radius * 0.75)
              ..lineTo(comp.pos.dx + radius * 0.866, comp.pos.dy + radius * 0.75)
              ..close();
            canvas.drawPath(path, fillPaint);
            canvas.drawPath(path, outlinePaint);
          }
          // --- DEFAULT (Circle) ---
          else {
            canvas.drawCircle(comp.pos, radius, fillPaint);
            canvas.drawCircle(comp.pos, radius, outlinePaint);
          }
        }
      } else {
        if (!showSpl) {
          final ui.Image? img = hardwareImages[comp.assetImagePath];
          if (img != null) {
            // draw the loaded image, scaling it into dst
            final ui.Rect src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
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
        }
      }

      // draw selection border - in acoustics mode, only show selection for speakers
      if (comp.id == selectedHardwareComponentId && (!isAcousticsMode || comp is Speaker)) {
        canvas.drawRect(
          Rect.fromCenter(center: comp.pos, width: gridSize, height: gridSize),
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

    final ui.Paint strSel = Paint()
      ..color = defaultListeningAreaColor
      ..strokeWidth = 3 / zoomScale
      ..style = PaintingStyle.stroke;
    final ui.Paint vPaint = Paint()
      ..color = defaultListeningAreaColor
      ..style = PaintingStyle.fill;
    final double vSize = 4.0 / zoomScale;
    final double dashLength = 8.0 / zoomScale;
    final double gapLength = 4.0 / zoomScale;

    // Draw dotted lines between consecutive points
    for (int i = 0; i < current.length - 1; i++) {
      _drawDottedLine(canvas, current[i], current[i + 1], strSel, dashLength, gapLength);
    }

    // Draw preview line to mouse position
    if (previewPoint != null) {
      _drawDottedLine(canvas, current.last, previewPoint!, strSel, dashLength, gapLength);
    }

    // Draw vertex circles
    for (final ui.Offset p in current) {
      canvas.drawCircle(p, vSize, vPaint);
    }
  }

  void _drawDottedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashLength, double gapLength) {
    final double distance = (end - start).distance;
    final Offset direction = (end - start) / distance;
    final double totalDashGap = dashLength + gapLength;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final Offset dashStart = start + direction * currentDistance;
      final double remainingDistance = distance - currentDistance;
      final double currentDashLength = dashLength > remainingDistance ? remainingDistance : dashLength;
      final Offset dashEnd = dashStart + direction * currentDashLength;

      canvas.drawLine(dashStart, dashEnd, paint);
      currentDistance += totalDashGap;
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
    return <ui.Offset>[p, p + Offset(w, 0), p + Offset(w, h), p + Offset(0, h)];
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

    List<Color> colors = SPLCalculationData.legendColors;
    if (splPanelData.splInvertColor) {
      colors = colors.reversed.toList();
    }

    return Color.lerp(colors[i0], colors[i1], f)!;
  }

  @override
  bool shouldRepaint(covariant FloorCanvasPainter old) {
    return old.gridSize != gridSize ||
        old.zoomScale != zoomScale ||
        old.panOffset != panOffset ||
        old.listeningAreas != listeningAreas ||
        old.zones != zones ||
        old.subZones != subZones ||
        old.current != current ||
        old.previewPoint != previewPoint ||
        old.highlightedIndex != highlightedIndex ||
        old.floorPlanEntity != floorPlanEntity ||
        old.floorPlanImageSelected != floorPlanImageSelected ||
        old.showSpl != showSpl ||
        old.hardwareComponents != hardwareComponents ||
        old.hardwareImages != hardwareImages ||
        old.selectedHardwareComponentId != selectedHardwareComponentId ||
        old.listeningAreaToZoneMap != listeningAreaToZoneMap ||
        old.listeningAreaToSubZoneMap != listeningAreaToSubZoneMap ||
        old.subZoneToZoneMap != subZoneToZoneMap ||
        old.isAcousticsMode != isAcousticsMode;
  }
}

class HeatMapData {
  final ListeningArea listeningArea;
  final Offset point;
  final double value;

  HeatMapData({required this.listeningArea, required this.point, required this.value});
}
