// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fusion_lib/fusion_utils/fusion_utilities.dart';

enum RecurrenceType {
  none,
  daily,
  weekly,
}

enum RecurrenceDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class ScheduleModel {
  final String id;
  final String name;
  final String color;
  final DateTime startDate;
  final DateTime endDate;

  final DateTime startTime;
  final DateTime endTime;

  final RecurrenceType recurrenceType;

  final List<RecurrenceDay> recurrenceDays;
  final String status;
  ScheduleModel({
    String? id,
    required this.name,
    required this.color,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.recurrenceType,
    required this.recurrenceDays,
    required this.status,
  }) : id = id ?? "SCH${FusionUtils.shortStringUUID()}";

  ScheduleModel copyWith({
    String? id,
    String? name,
    String? color,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startTime,
    DateTime? endTime,
    RecurrenceType? recurrenceType,
    List<RecurrenceDay>? recurrenceDays,
    String? status,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'color': color,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'recurrenceType': recurrenceType.name,
      'recurrenceDays': recurrenceDays.map((RecurrenceDay x) => x.name).toList(),
      'status': status,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      color: (map['color'] ?? '') as String,
      startDate: DateTime.fromMillisecondsSinceEpoch((map['startDate'] ?? 0) as int),
      endDate: DateTime.fromMillisecondsSinceEpoch((map['endDate'] ?? 0) as int),
      startTime: DateTime.fromMillisecondsSinceEpoch((map['startTime'] ?? 0) as int),
      endTime: DateTime.fromMillisecondsSinceEpoch((map['endTime'] ?? 0) as int),
      recurrenceType: RecurrenceType.values.firstWhere(
        (RecurrenceType x) => x.name == (map['recurrenceType'] ?? 'none'),
        orElse: () => RecurrenceType.none,
      ),
      recurrenceDays: List<RecurrenceDay>.from(
        (map['recurrenceDays'] as List<String>).map<RecurrenceDay>(
          (String x) => RecurrenceDay.values.firstWhere(
            (RecurrenceDay day) => day.name == x,
            orElse: () => RecurrenceDay.monday,
          ),
        ),
      ),
      status: (map['status'] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleModel.fromJson(String source) => ScheduleModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ScheduleModel(id: $id, name: $name, color: $color, startDate: $startDate, endDate: $endDate, startTime: $startTime, endTime: $endTime, recurrenceType: $recurrenceType, recurrenceDays: $recurrenceDays, status: $status)';
  }

  @override
  bool operator ==(covariant ScheduleModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.color == color &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.recurrenceType == recurrenceType &&
        listEquals(other.recurrenceDays, recurrenceDays) &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        color.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        recurrenceType.hashCode ^
        recurrenceDays.hashCode ^
        status.hashCode;
  }
}
