import 'package:flutter/material.dart';

class ZoneModel {
  final String id;
  final String name;
  final List<ZoneSourceModel> sources;

  ZoneModel({
    required this.id,
    required this.name,
    required this.sources,
  });

  ZoneModel copyWith({
    String? id,
    String? name,
    List<ZoneSourceModel>? sources,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sources: sources ?? this.sources,
    );
  }
}

class ZoneSourceModel {
  final String id;
  final String name;
  final IconData icon;
  final int volume;
  final bool muted;

  ZoneSourceModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.volume,
    this.muted = false,
  });

  bool selected = false;

  ZoneSourceModel copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? volume,
    bool? muted,
  }) {
    return ZoneSourceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      volume: volume ?? this.volume,
      muted: muted ?? this.muted,
    );
  }
}