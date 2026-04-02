import 'package:flutter/material.dart';

class ZoneModel {
  final String id;
  final String name;
  final String gainID;
  final List<ZoneSourceModel> sources;

  ZoneModel({
    required this.id,
    required this.name,
    required this.gainID,
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
      gainID: gainID ?? this.gainID,
      sources: sources ?? this.sources,
    );
  }

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'],
      name: json['name'],
      gainID: json['gainID'],
      sources: (json['sources'] as List)
          .map((e) => ZoneSourceModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sources': sources.map((e) => e.toJson()).toList(),
    };
  }
}

class ZoneSourceModel {
  final String id;
  final String name;
  final IconData icon;
  final int volume;
  final bool muted;

  bool selected = false;

  ZoneSourceModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.volume,
    this.muted = false,
  });

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
    )..selected = selected;
  }

  factory ZoneSourceModel.fromJson(Map<String, dynamic> json) {
    final model = ZoneSourceModel(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      volume: json['volume'],
      muted: json['muted'] ?? false,
    );

    model.selected = json['selected'] ?? false;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      //'icon_codePoint': icon.codePoint,
      'volume': volume,
      'muted': muted,
      'selected': selected,
    };
  }
}