import 'package:fusion_lib/fusion_lib.dart';

class FusionCanvasLine extends FusionCanvasElement {
  final FusionCanvasPoint start;
  final FusionCanvasPoint end;

  FusionCanvasLine({required this.start, required this.end});
  @override
  String get id => '${start.id}_${end.id}';

  bool get isVerticalLine => (start.position.dx - end.position.dx).abs() < (start.position.dy - end.position.dy).abs();
}
