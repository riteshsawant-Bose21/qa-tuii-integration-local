import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/derived/listening_area_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_launcher/features/projects/view_model/spl_viewmodel.dart';
import 'package:fusion_lib/fusion_acoustic_calculation_engine/spl_calculation_data.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SplPainter extends FusionBasePainter {
  final List<ListeningAreaPainter> listeningAreas;
  final double minSpl;
  final double maxSpl;
  final SplPanelData splPanelData;
  final SplState splState;
  final int livePointStride;
  final List<Color> _legendColors;

  final double gridSize = 100;
  double get pointSize => (gridSize / 2);
  SplPainter({
    required this.listeningAreas,
    required this.minSpl,
    required this.maxSpl,
    required this.splPanelData,
    required this.splState,
    this.livePointStride = 4,
  }) : _legendColors = splPanelData.splInvertColor ? List<Color>.of(SPLCalculationData.legendColors.reversed) : SPLCalculationData.legendColors;

  bool get isLiveSpl => splState is LiveSplState;

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

  List<Color> _buildColorLut([int lutSize = 256]) {
    final int safeSize = lutSize.clamp(2, 4096);
    final List<Color> lut = List<Color>.filled(safeSize, const Color(0x00000000), growable: false);

    if (maxSpl <= minSpl) {
      final Color fallback = _legendColors.isEmpty ? const Color(0x00000000) : _legendColors.first;
      for (int i = 0; i < safeSize; i++) {
        lut[i] = fallback;
      }
      return lut;
    }

    final double range = maxSpl - minSpl;
    for (int i = 0; i < safeSize; i++) {
      final double t = i / (safeSize - 1);
      lut[i] = _colorFromLegend(minSpl + (t * range));
    }
    return lut;
  }

  _HeatmapSignature _computeHeatmapSignature() {
    final int effectiveStride = isLiveSpl ? livePointStride.clamp(1, 1 << 20) : 1;
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
      isLive: isLiveSpl,
      livePointStride: effectiveStride,
      areas: summaries,
    );
  }

  void _buildHeatmapPicture(Canvas canvas) {
    final int effectiveStride = isLiveSpl ? livePointStride.clamp(1, 1 << 20) : 1;
    final double cellPointSize = pointSize;
    final Path tmpPath = Path();
    final Paint drawImagePaint = Paint();
    final List<Color> colorLut = _buildColorLut();
    final int maxColorIdx = colorLut.length - 1;
    final double splRange = maxSpl - minSpl;
    final double invSplRange = splRange > 0 ? 1.0 / splRange : 0.0;

    for (final ListeningAreaPainter listeningAreaPainter in listeningAreas) {
      final ListeningArea listeningArea = listeningAreaPainter.listeningArea;
      final SplData? spl = listeningArea.splData;

      tmpPath.reset();
      tmpPath.addPolygon(listeningArea.vertices.map((FusionCanvasPoint v) => v.position).toList(), true);
      final Rect bounds = tmpPath.getBounds();

      if (bounds.width <= 0 || bounds.height <= 0 || spl == null) {
        print("Skipping area ${listeningArea.name} due to invalid bounds or missing SPL data. Bounds: $bounds, SPL: ${spl == null ? 'null' : 'available'}");
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
        final List<Offset> points = spl.fieldPoints;
        final List<double> values = spl.splValues;
        final int count = points.length < values.length ? points.length : values.length;
        if (count == 0) {
          final PictureRecorder emptyRecorder = PictureRecorder();
          final Picture emptyPic = emptyRecorder.endRecording();
          return emptyPic.toImageSync(1, 1);
        }

        final _SplSortKey sortKey = _SplSortKey(
          splRef: spl,
          fieldPointsLen: points.length,
          splValuesLen: values.length,
          stride: effectiveStride,
        );
        final List<int> sortedIndices = _HeatmapCache.instance.getOrBuildSortedIndices(sortKey, values, count, effectiveStride);

        final PictureRecorder areaRecorder = PictureRecorder();
        final Canvas areaCanvas = Canvas(areaRecorder);

        areaCanvas.translate(-bounds.left, -bounds.top);
        areaCanvas.save();
        areaCanvas.clipPath(tmpPath);

        final Paint pointPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

        for (int i = 0; i < sortedIndices.length; i++) {
          final int idx = sortedIndices[i];
          if (idx < 0 || idx >= count) {
            continue;
          }

          final double normalized = invSplRange > 0 ? (values[idx] - minSpl) * invSplRange : 0.0;
          final int lutIndex = (normalized * maxColorIdx).round().clamp(0, maxColorIdx);
          pointPaint.color = colorLut[lutIndex];
          areaCanvas.drawRect(Rect.fromCenter(center: points[idx], width: cellPointSize, height: cellPointSize), pointPaint);
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
  final Map<_SplSortKey, List<int>> _sortedIndicesCache = <_SplSortKey, List<int>>{};

  void checkWithSignature(_HeatmapSignature sig) {
    final _HeatmapSignature? previous = _currentSignature;
    if (previous != sig) {
      _clearImages();

      // Keep sorted indices when only visual range/inversion changes.
      if (previous == null || !previous.hasSameSplLayout(sig)) {
        _sortedIndicesCache.clear();
      }

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

  List<int> getOrBuildSortedIndices(_SplSortKey key, List<double> values, int count, int stride) {
    final List<int>? existing = _sortedIndicesCache[key];
    if (existing != null) {
      return existing;
    }

    final int safeStride = stride.clamp(1, 1 << 20);
    final int sampledCount = (count + safeStride - 1) ~/ safeStride;
    final List<int> indices = List<int>.generate(sampledCount, (int i) => i * safeStride, growable: false);
    indices.sort((int a, int b) => values[a].compareTo(values[b]));
    _sortedIndicesCache[key] = indices;
    return indices;
  }

  void clear() {
    _clearImages();
    _sortedIndicesCache.clear();
  }

  void _clearImages() {
    for (final Image image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }
}

class _HeatmapSignature {
  final double splMin;
  final double splMax;
  final bool invert;
  final double gridSize;
  final bool isLive;
  final int livePointStride;
  final List<_AreaSplSummary> areas;

  const _HeatmapSignature({
    required this.splMin,
    required this.splMax,
    required this.invert,
    required this.gridSize,
    required this.isLive,
    required this.livePointStride,
    required this.areas,
  });

  bool hasSameSplLayout(_HeatmapSignature other) {
    if (gridSize != other.gridSize || areas.length != other.areas.length) {
      return false;
    }

    for (int i = 0; i < areas.length; i++) {
      if (areas[i] != other.areas[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _HeatmapSignature) return false;

    if (splMin != other.splMin ||
        splMax != other.splMax ||
        invert != other.invert ||
        gridSize != other.gridSize ||
        isLive != other.isLive ||
        livePointStride != other.livePointStride) {
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
    int h = splMin.hashCode ^ splMax.hashCode ^ invert.hashCode ^ gridSize.hashCode ^ isLive.hashCode ^ livePointStride.hashCode;
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

class _SplSortKey {
  final Object? splRef;
  final int fieldPointsLen;
  final int splValuesLen;
  final int stride;

  const _SplSortKey({
    required this.splRef,
    required this.fieldPointsLen,
    required this.splValuesLen,
    required this.stride,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _SplSortKey) return false;

    return identical(splRef, other.splRef) && fieldPointsLen == other.fieldPointsLen && splValuesLen == other.splValuesLen && stride == other.stride;
  }

  @override
  int get hashCode => identityHashCode(splRef) ^ fieldPointsLen.hashCode ^ splValuesLen.hashCode ^ stride.hashCode;
}
