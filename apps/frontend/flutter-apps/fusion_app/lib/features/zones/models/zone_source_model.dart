import 'package:flutter/material.dart';
import 'package:fusion_app/core/models/scheme_model.dart';

class ZoneModel {
  final String id;
  final String name;
  final List<ZoneSourceModel> subZones;
  final List<Source> sources;

  ZoneModel({
    required this.id,
    required this.name,
    required this.subZones,
    required this.sources,
  });

  ZoneModel copyWith({
    String? id,
    String? name,
    List<ZoneSourceModel>? subZone,
    List<Source>? sources,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subZones: subZone ?? this.subZones,
      sources: sources ?? this.sources,
    );
  }

  int sourceSelected = 0;

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'],
      name: json['name'],
      subZones: (json['subZones'] as List)
          .map((e) => ZoneSourceModel.fromJson(e))
          .toList(),
      sources: (json['sources'] as List)
          .map((e) => Source.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subZones': subZones.map((e) => e.toJson()).toList(),
      'sources': sources.map((e) => e.toJson()).toList(),
    };
  }
}

class ZoneSourceModel {
  final String id;
  final String name;
  final String gainID;
  final IconData icon;
  final double volume;
  final bool muted;
  final int? timestamp;


  ZoneSourceModel({
    required this.id,
    required this.name,
    required this.gainID,
    required this.icon,
    required this.volume,
    this.muted = false,
    this.timestamp,
  });

  ZoneSourceModel copyWith({
    String? id,
    String? name,
    String? gainID,
    IconData? icon,
    double? volume,
    bool? muted,
    int? timestamp,
  }) {
    return ZoneSourceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gainID: gainID ?? this.gainID,
      icon: icon ?? this.icon,
      volume: volume ?? this.volume,
      muted: muted ?? this.muted,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory ZoneSourceModel.fromJson(Map<String, dynamic> json) {
    final model = ZoneSourceModel(
      id: json['id'],
      name: json['name'],
      gainID: json['gainID'],
      icon: json['icon'],
      volume: json['volume'],
      timestamp: json['timestamp'],
      muted: json['muted'] ?? false,
    );

    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gainID': gainID,
      'volume': volume,
      'muted': muted,
    };
  }
}