import 'package:fusion_lib/fusion_utils/fusion_utilities.dart';

import 'fusion_canvas_element.dart';
import 'fusion_canvas_point.dart';

class FusionCanvasPolygon extends FusionCanvasElement {
  final List<FusionCanvasPoint> points;
  FusionCanvasPolygon({
    required this.points,
    String? id,
  }) : id = id ?? FusionUtils.generateUUID();

  @override
  final String id;

  @override
  List<String> get pointIds => points.map((FusionCanvasPoint e) => e.id).toList();
}

class FusionCanvasPath extends FusionCanvasElement {
  final List<FusionCanvasPoint> points;

  FusionCanvasPath({required this.points, String? id}) : id = id ?? FusionUtils.generateUUID();

  @override
  final String id;

  @override
  List<String> get pointIds => points.map((FusionCanvasPoint e) => e.id).toList();
}
