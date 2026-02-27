// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

class FusionCanvasPoint {
  final Offset position;

  final Offset? handleIn;
  final Offset? handleOut;

  FusionCanvasPoint({required this.position, this.handleIn, this.handleOut});

  @override
  bool operator ==(covariant FusionCanvasPoint other) {
    if (identical(this, other)) return true;

    return other.position == position && other.handleIn == handleIn && other.handleOut == handleOut;
  }

  @override
  int get hashCode => position.hashCode ^ handleIn.hashCode ^ handleOut.hashCode;
}
