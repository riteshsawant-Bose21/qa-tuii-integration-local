// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FusionCanvasInputState {
  final Offset? mousePosition;
  final List<LogicalKeyboardKey> pressedKeys;

  FusionCanvasInputState({required this.mousePosition, required this.pressedKeys});

  @override
  bool operator ==(covariant FusionCanvasInputState other) {
    if (identical(this, other)) return true;

    return other.mousePosition == mousePosition && listEquals(other.pressedKeys, pressedKeys);
  }

  @override
  int get hashCode => mousePosition.hashCode ^ pressedKeys.hashCode;
}
