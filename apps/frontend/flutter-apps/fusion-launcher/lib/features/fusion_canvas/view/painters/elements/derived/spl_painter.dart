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
  final List<Color> _legendColors;

  final double gridSize = 100;
  double get pointSize => gridSize / 2;

  SplPainter({required this.listeningAreas, required this.minSpl, required this.maxSpl, required this.splPanelData})
    : _legendColors = splPanelData.splInvertColor ? List<Color>.of(SPLCalculationData.legendColors.reversed) : SPLCalculationData.legendColors;

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final _HeatmapSignature currentSig = _computeHeatmapSignature();
    _HeatmapCache.instance.checkWithSignature(currentSig);
    _buildHeatmapPicture(canvas);
  }

  Color _colorFromLegend(double v) {
    if (_legendColors.isEmpty) {
      return const Color(0x00000000);
    }
    if (maxSpl <= minSpl) {
      return _legendColors.first;
    }

    final double c = v.clamp(minSpl, maxSpl);
    final double t = (c - minSpl) / (maxSpl - minSpl);
    final int n = _legendColors.length;
    final double idx = t * (n - 1);
    final int i0 = idx.floor().clamp(0, n - 1);
    final int i1 = idx.ceil().clamp(0, n - 1);
    final double f = idx - i0;

    return Color.lerp(_legendColors[i0], _legendColors[i1], f)!;
  }

  List<HeatMapData> _buildSortedAreaHeatMapEntries(SplData spl) {
    final List<Offset> points = spl.fieldPoints;
    final List<double> values = spl.splValues;
    final int count = points.length < values.length ? points.length : values.length;

    final List<HeatMapData> entries = List<HeatMapData>.generate(
      count,
      (int i) => HeatMapData(point: points[i], value: values[i]),
      growable: false,
    );

    entries.sort((HeatMapData a, HeatMapData b) => a.value.compareTo(b.value));
    return entries;
  }

  _HeatmapSignature _computeHeatmapSignature() {
    final List<_AreaSplSummary> summaries = <_AreaSplSummary>[];
    for (int i = 0; i < listeningAreas.length; i++) {
      final ListeningAreaPainter aPainter = listeningAreas[i];
      final ListeningArea area = aPainter.listeningArea;
      final SplData? spl = area.splData;
      summaries.add(
        _AreaSplSummary(
          id: area.id,
          splRef: spl,
          fieldPointsLen: spl?.fieldPoints.length ?? -1,
          splValuesLen: spl?.splValues.length ?? -1,
          vertices: area.vertices.map((FusionCanvasPoint v) => v.position).toList(),
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

  void _buildHeatmapPicture(Canvas canvas) {
    final double cellPointSize = pointSize;
    final Path tmpPath = Path();
    final Paint drawImagePaint = Paint();

    for (final ListeningAreaPainter listeningAreaPainter in listeningAreas) {
      final ListeningArea listeningArea = listeningAreaPainter.listeningArea;
      final SplData? spl = listeningArea.splData;

      tmpPath.reset();
      tmpPath.addPolygon(listeningArea.vertices.map((FusionCanvasPoint v) => v.position).toList(), true);
      final Rect bounds = tmpPath.getBounds();

      if (bounds.width <= 0 || bounds.height <= 0 || spl == null) {
        continue;
      }

      final _AreaSplSummary cacheKey = _AreaSplSummary(
        id: listeningArea.id,
        splRef: spl,
        fieldPointsLen: spl.fieldPoints.length,
        splValuesLen: spl.splValues.length,
        vertices: listeningArea.vertices.map((FusionCanvasPoint v) => v.position).toList(),
      );

      final Image areaImage = _HeatmapCache.instance.getOrBuild(cacheKey, () {
        final List<HeatMapData> areaHeatMapData = _buildSortedAreaHeatMapEntries(spl);

        final PictureRecorder areaRecorder = PictureRecorder();
        final Canvas areaCanvas = Canvas(areaRecorder);

        areaCanvas.translate(-bounds.left, -bounds.top);
        areaCanvas.save();
        areaCanvas.clipPath(tmpPath);

        final Paint pointPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

        for (final HeatMapData data in areaHeatMapData) {
          final double v = data.value.clamp(minSpl, maxSpl);
          pointPaint.color = _colorFromLegend(v);
          areaCanvas.drawRect(Rect.fromCenter(center: data.point, width: cellPointSize, height: cellPointSize), pointPaint);
        }

        areaCanvas.restore();

        final Picture pic = areaRecorder.endRecording();
        final int imageWidth = bounds.width.ceil().clamp(1, 1 << 20);
        final int imageHeight = bounds.height.ceil().clamp(1, 1 << 20);
        return pic.toImageSync(imageWidth, imageHeight);
      });

      final Rect src = Rect.fromLTWH(0, 0, areaImage.width.toDouble(), areaImage.height.toDouble());
      final Rect dst = bounds;
      canvas.drawImageRect(areaImage, src, dst, drawImagePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}

class _HeatmapCache {
  _HeatmapCache._();

  static final _HeatmapCache instance = _HeatmapCache._();

  _HeatmapSignature? _currentSignature;
  final Map<_AreaSplSummary, Image> _cache = <_AreaSplSummary, Image>{};

  void checkWithSignature(_HeatmapSignature sig) {
    if (_currentSignature != sig) {
      clear();
      _currentSignature = sig;
    }
  }

  Image getOrBuild(_AreaSplSummary key, Image Function() builder) {
    final Image? existing = _cache[key];
    if (existing != null) {
      return existing;
    }

    final Image img = builder();
    _cache[key] = img;
    return img;
  }

  void clear() {
    for (final Image image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }
}

class HeatMapData {
  final Offset point;
  final double value;

  HeatMapData({required this.point, required this.value});
}

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
  final Object? splRef;
  final int fieldPointsLen;
  final int splValuesLen;
  final List<Offset> vertices;

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

  bool _listEquals(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
