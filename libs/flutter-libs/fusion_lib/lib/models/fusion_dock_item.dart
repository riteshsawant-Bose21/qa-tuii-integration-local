import 'dart:ui';

class DockItem {
  String id;
  String title;
  bool docked;
  Offset position;
  String side; // "left" or "right"
  double width;
  double height;
  bool expanded;
  int? zIndex;
  int? dockedOrder;

  DockItem({
    required this.id,
    required this.title,
    this.docked = true,
    this.position = const Offset(200, 200),
    this.side = "left",
    this.width = 240,
    this.height = 650,
    this.expanded = false,
    this.zIndex,
    this.dockedOrder,
  });
}
