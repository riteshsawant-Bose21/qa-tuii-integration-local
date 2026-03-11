import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/derived/listening_area_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_acoustic_calculation_engine/spl_calculation_data.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SplPainter extends FusionBasePainter {
  final List<ListeningAreaPainter> listeningAreas;
  final double minSpl;
  final double maxSpl;
  final SplPanelData splPanelData;

  SplPainter({required this.listeningAreas, required this.minSpl, required this.maxSpl, required this.splPanelData});
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final List<HeatMapData> heatMapData = _buildSortedHeatMapEntries();
    final double gridSize = 100;
    final double pointSize = gridSize / 2;

    for (final ListeningAreaPainter p in listeningAreas) {
      final ListeningArea listeningArea = p.listeningArea;
      final SplData? spl = listeningArea.splData;
      if (spl == null) continue;
      final Path? path = getPolygonPath(p.polygon, painter);
      if (path == null) continue;

      canvas.save();
      canvas.clipPath(path);
      // 2) draw *all* points for that listeningArea
      for (final HeatMapData data in heatMapData.where((HeatMapData e) => e.listeningArea == listeningArea)) {
        final double v = data.value.clamp(minSpl, maxSpl);
        final Color color = _colorFromLegend(v);

        final Paint paint =
            Paint()
              ..color = color
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

        canvas.drawRect(Rect.fromCenter(center: data.point, width: pointSize, height: pointSize), paint);
      }
      canvas.restore();
    }
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

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    // TODO: implement shouldRepaint
    throw UnimplementedError();
  }
}
