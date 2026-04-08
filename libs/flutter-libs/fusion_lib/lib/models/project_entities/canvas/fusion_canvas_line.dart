// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

class FusionCanvasLine extends FusionCanvasElement {
  final FusionCanvasPoint start;
  final FusionCanvasPoint end;

  FusionCanvasLine({required this.start, required this.end});
  @override
  String get id => '${start.id}_${end.id}';

  bool get isVerticalLine => (start.position.dx - end.position.dx).abs() < (start.position.dy - end.position.dy).abs();

  @override
  List<String> get pointIds => [start.id, end.id];

  @override
  String toString() => 'FusionCanvasLine(id: $id, start: $start, end: $end)';

  Offset get center => Offset((start.position.dx + end.position.dx) / 2, (start.position.dy + end.position.dy) / 2);
}

class FusionCanvasPathSegment extends FusionCanvasElement {
  final FusionCanvasPoint start;
  final FusionCanvasPoint end;

  FusionCanvasPathSegment({required this.start, required this.end});
  @override
  String get id => '${start.id}_${end.id}';

  bool get isVerticalLine => (start.position.dx - end.position.dx).abs() < (start.position.dy - end.position.dy).abs();

  @override
  List<String> get pointIds => [start.id, end.id];

  @override
  String toString() => 'FusionCanvasLine(id: $id, start: $start, end: $end)';

  Offset get center => Offset((start.position.dx + end.position.dx) / 2, (start.position.dy + end.position.dy) / 2);
}
