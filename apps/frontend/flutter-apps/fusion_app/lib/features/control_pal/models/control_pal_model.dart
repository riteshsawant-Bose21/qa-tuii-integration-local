import 'package:flutter/material.dart';

class BottomNavItemModel<T> {
  final IconData icon;
  final String label;
  final T selected;

  const BottomNavItemModel({
    required this.selected,
    required this.icon,
    required this.label,
  });
}
