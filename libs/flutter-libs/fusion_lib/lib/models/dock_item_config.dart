import 'package:flutter/material.dart';

class DockItemConfig {
  final String id;
  final String title;
  final String side;
  final bool initiallyExpanded;
  final bool allowUndock;
  final bool isVisible;
  final bool isCollapsibleSection;
  final ExpansibleController? controller;

  final Widget dockItemWidget;

  const DockItemConfig({
    required this.id,
    required this.title,
    required this.side,
    required this.dockItemWidget,
    this.initiallyExpanded = false,
    this.allowUndock = true,
    this.isCollapsibleSection = true,
    this.controller,
    this.isVisible = true,
  });
}
