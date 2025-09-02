import 'package:flutter/material.dart';

class DockItemConfig {
  final String id;
  final String title;
  final String side;
  final Widget Function() widgetBuilder;

  const DockItemConfig({required this.id, required this.title, required this.side, required this.widgetBuilder});
}
