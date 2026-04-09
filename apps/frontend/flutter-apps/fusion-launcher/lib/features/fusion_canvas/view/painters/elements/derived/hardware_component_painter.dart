import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_element_painter.dart';
import 'hardware_painter/source_painter.dart';
import 'hardware_painter/speaker_painter.dart';

class HardwareComponentPainter extends FusionCanvasElementPainter {
  final HardwareComponent hardware;
  late final FusionCanvasElementPainter? painter;
  HardwareComponentPainter({required this.hardware}) : super(item: FusionCanvasItem(id: hardware.id)) {
    if (hardware is Speaker) {
      painter = SpeakerPainter(hardware: hardware as Speaker);
    } else if (hardware is Source) {
      painter = SourcePainter(hardware: hardware as Source);
    } else {
      painter = null;
    }
  }
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    this.painter?.paint(canvas, size, painter);
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! HardwareComponentPainter) return true;
    return oldDelegate.hardware != hardware;
  }

  @override
  Offset getOffset() => painter?.getOffset() ?? Offset.zero;

  @override
  Size getSize() => painter?.getSize() ?? Size.zero;

  // @override
  // Path getBoundPath(FusionCanvasPainter painter) {
  //   final String? listiningAreaId = hardware.locationEntity.listeningAreaId;
  //   final ListeningAreaPainter? listingAreaPainter =
  //       painter.layers.whereType<ListeningAreaPainter>().where((ListeningAreaPainter p) => p.id == listiningAreaId).firstOrNull;
  //   return listingAreaPainter?.getPath(painter) ?? Path()
  //     ..addRect(getTransformedRect(painter));
  // }
}
