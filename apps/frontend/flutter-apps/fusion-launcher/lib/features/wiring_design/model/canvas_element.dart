import 'dart:ui';

abstract class CanvasElement {
  String get id;
  Offset get position; // Top-left corner
  Size get size;

  Map<String, dynamic> toMap();

  void restoreFromMap(Map<dynamic, dynamic> map);
}
