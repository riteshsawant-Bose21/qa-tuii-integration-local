import 'package:flutter/material.dart';

class DockItemConfig {
  final String id;
  final String title;
  final String side;
  final bool initiallyExpanded;
  final bool alowUndock;
  final bool isCollapsibleSection;

  final Widget Function() dockItemWidget;

  const DockItemConfig({
    required this.id,
    required this.title,
    required this.side,
    required this.dockItemWidget,
    this.initiallyExpanded = false,
    this.alowUndock = true,
    this.isCollapsibleSection = true,
  });
}
