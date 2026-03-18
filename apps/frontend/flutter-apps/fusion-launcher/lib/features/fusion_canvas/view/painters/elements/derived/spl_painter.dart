import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/derived/listening_area_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_acoustic_calculation_engine/spl_calculation_data.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SplPainter extends FusionBasePainter {
  final List<ListeningAreaPainter> listeningAreas;
  final double minSpl;
  final double maxSpl;
  final SplPanelData splPanelData;
  final double gridSize = 100;
  double get pointSize => gridSize / 2;
  SplPainter({required this.listeningAreas, required this.minSpl, required this.maxSpl, required this.splPanelData});
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final _HeatmapSignature currentSig = _computeHeatmapSignature();
    _HeatmapCache.instance.checkWithSignature(currentSig);
    // if (pic != null) {
    //   canvas.drawPicture(pic);
    // }
    _buildHeatmapPicture(size, canvas);
  }

  Color _colorFromLegend(double v) {
    final double c = v.clamp(minSpl, maxSpl);
    final double t = (c - minSpl) / (maxSpl - minSpl);
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

  List<HeatMapData> _buildSortedHeatMapEntries() {
    final List<HeatMapData> entries = <HeatMapData>[];
    for (final ListeningAreaPainter painter in listeningAreas) {
      final ListeningArea s = painter.listeningArea;
      final SplData? spl = s.splData;
      if (spl == null) continue;
      final List<Offset> pts = spl.fieldPoints;
      final List<double> vals = spl.splValues;
      if (pts.length != vals.length) continue;
      for (int i = 0; i < pts.length; i++) {
        entries.add(HeatMapData(listeningArea: s, point: pts[i], value: vals[i]));
      }
    }
    entries.sort((HeatMapData a, HeatMapData b) => a.value.compareTo(b.value));
    return entries;
  }

  _HeatmapSignature _computeHeatmapSignature() {
    // Collect minimal info impacting heatmap content
    final List<_AreaSplSummary> summaries = <_AreaSplSummary>[];
    // summaries.length = listeningAreas.length;
    for (int i = 0; i < listeningAreas.length; i++) {
      final ListeningAreaPainter aPainter = listeningAreas[i];
      final ListeningArea a = aPainter.listeningArea;
      final SplData? s = a.splData;
      summaries.add(
        _AreaSplSummary(
          id: a.id,
          splRef: s,
          fieldPointsLen: s?.fieldPoints.length ?? -1,
          splValuesLen: s?.splValues.length ?? -1,
          vertices: a.vertices.map((FusionCanvasPoint v) => v.position).toList(),
        ),
      );
    }
    return _HeatmapSignature(
      splMin: minSpl,
      splMax: maxSpl,
      invert: splPanelData.splInvertColor,
      gridSize: gridSize,
      areas: summaries,
    );
  }

  void _buildHeatmapPicture(Size paintSize, Canvas canvas) {
    final List<HeatMapData> heatMapData = _buildSortedHeatMapEntries();
    final double pointSize = gridSize / 2;

    final Path tmpPath = Path();

    for (final ListeningAreaPainter listeningAreaPainter in listeningAreas) {
      final ListeningArea listeningArea = listeningAreaPainter.listeningArea;
      final SplData? spl = listeningArea.splData;

      // Clip to listening area polygon once
      tmpPath.reset();
      tmpPath.addPolygon(listeningArea.vertices.map((FusionCanvasPoint v) => v.position).toList(), true);
      final Rect bounds = tmpPath.getBounds();

      // Skip if bounds are invalid
      if (bounds.width <= 0 || bounds.height <= 0) continue;

      if (spl == null) {
        // Paint loading shimmer when splData is null
        // _drawLoadingShimmer(canvas, tmpPath, bounds);
        continue;
      }

      final Image pic = _HeatmapCache.instance.getOrBuild(
        _AreaSplSummary(
          id: listeningArea.id,
          splRef: spl,
          fieldPointsLen: spl.fieldPoints.length,
          splValuesLen: spl.splValues.length,
          vertices: listeningArea.vertices.map((FusionCanvasPoint v) => v.position).toList(),
        ),
        () {
          final PictureRecorder areaRecorder = PictureRecorder();
          final Canvas areaCanvas = Canvas(areaRecorder);

          // Translate canvas so the picture's origin aligns with bounds.topLeft
          areaCanvas.translate(-bounds.left, -bounds.top);
          areaCanvas.save();
          areaCanvas.clipPath(tmpPath);

          // Draw all points for that listening area
          for (final HeatMapData data in heatMapData.where((HeatMapData e) => e.listeningArea == listeningArea)) {
            final double v = data.value.clamp(minSpl, maxSpl);
            final Color color = _colorFromLegend(v);

            final Paint paint =
                Paint()
                  ..color = color
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

            areaCanvas.drawRect(Rect.fromCenter(center: data.point, width: pointSize, height: pointSize), paint);
          }
          areaCanvas.restore();
          final Picture pic = areaRecorder.endRecording();
          return pic.toImageSync(bounds.width.toInt(), bounds.height.toInt());
        },
      );

      // Draw the cached image using explicit src/dst rects to ensure correct placement
      final Rect src = Rect.fromLTWH(0, 0, pic.width.toDouble(), pic.height.toDouble());
      final Rect dst = bounds;
      canvas.drawImageRect(pic, src, dst, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}

// Global/static heatmap cache keyed by signature, survives painter instance recreation
class _HeatmapCache {
  _HeatmapCache._();
  final bool log = false;
  static final _HeatmapCache instance = _HeatmapCache._();
  _HeatmapSignature? _currentSignature;

  void checkWithSignature(_HeatmapSignature sig) {
    if (_currentSignature != sig) {
      if (log) print('[HeatmapCache] Signature changed, clearing cache');
      clear();
      _currentSignature = sig;
    }
  }

  final Map<_AreaSplSummary, Image> _cache = <_AreaSplSummary, Image>{};

  Image getOrBuild(_AreaSplSummary key, Image Function() builder) {
    final Image? existing = _cache[key];
    if (existing != null) {
      if (log) print('[HeatmapCache] Using cached Image for signature');
      return existing;
    }
    if (log) print('[HeatmapCache] Building new Image for signature');
    final Image img = builder();
    _cache[key] = img;
    return img;
  }

  void clear() => _cache.clear();
}

class HeatMapData {
  final ListeningArea listeningArea;
  final Offset point;
  final double value;

  HeatMapData({required this.listeningArea, required this.point, required this.value});
}

// Lightweight signature types used to detect input changes without relying on shouldRepaint lifecycle
class _HeatmapSignature {
  final double splMin;
  final double splMax;
  final bool invert;
  final double gridSize;
  final List<_AreaSplSummary> areas;

  const _HeatmapSignature({
    required this.splMin,
    required this.splMax,
    required this.invert,
    required this.gridSize,
    required this.areas,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _HeatmapSignature) return false;
    if (splMin != other.splMin || splMax != other.splMax || invert != other.invert || gridSize != other.gridSize) {
      return false;
    }
    if (areas.length != other.areas.length) return false;
    for (int i = 0; i < areas.length; i++) {
      if (areas[i] != other.areas[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int h = splMin.hashCode ^ splMax.hashCode ^ invert.hashCode ^ gridSize.hashCode;
    for (final _AreaSplSummary a in areas) {
      h = h * 31 ^ a.hashCode;
    }
    return h;
  }
}

class _AreaSplSummary {
  final String id;
  final Object? splRef; // identity only
  final int fieldPointsLen;
  final int splValuesLen;
  final List<Offset> vertices; // listening area points

  const _AreaSplSummary({
    required this.id,
    required this.splRef,
    required this.fieldPointsLen,
    required this.splValuesLen,
    required this.vertices,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _AreaSplSummary) return false;
    return id == other.id &&
        identical(splRef, other.splRef) &&
        fieldPointsLen == other.fieldPointsLen &&
        splValuesLen == other.splValuesLen &&
        _listEquals(vertices, other.vertices);
  }

  @override
  int get hashCode => id.hashCode ^ identityHashCode(splRef) ^ fieldPointsLen.hashCode ^ splValuesLen.hashCode ^ Object.hashAll(vertices);

  // Helper method to compare lists of Offsets
  bool _listEquals(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
