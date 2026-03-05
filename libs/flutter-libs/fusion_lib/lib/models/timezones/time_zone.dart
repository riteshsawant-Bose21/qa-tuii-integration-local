import 'dart:convert';

import 'package:fusion_lib/constants/time_zones_data.dart';

class TimeZoneModel {
  final String name;
  final String region;
  final String offset;

  TimeZoneModel({
    required this.name,
    required this.region,
    required this.offset,
  });

  factory TimeZoneModel.fromJson(Map<String, dynamic> json) {
    return TimeZoneModel(
      name: json['name'],
      region: json['region'],
      offset: json['offset'],
    );
  }

  static List<TimeZoneModel> getAllTimeZones() {
    final List<Map<String, String>> data = allTimeZonesJson;
    return data.map((e) => TimeZoneModel.fromJson(e)).toList();
  }

  String get displayName => "$name -$offset";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimeZoneModel && other.region == region && other.name == name && other.offset == offset;
  }

  @override
  int get hashCode => name.hashCode ^ region.hashCode ^ offset.hashCode;
}
