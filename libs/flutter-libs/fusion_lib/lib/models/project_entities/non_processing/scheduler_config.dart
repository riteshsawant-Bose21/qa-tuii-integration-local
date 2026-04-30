enum RecurrenceType {
  none("Once"),
  daily("Daily"),
  weekly("Weekly");

  final String label;
  const RecurrenceType(this.label);
}

enum RecurrenceDay {
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6),
  sunday(7);

  final int value;
  const RecurrenceDay(this.value);
}

class ScheduleConfig {
  final String id;
  final String name;
  final String colorHex;
  final DateTime startDate;
  final DateTime time;
  final DateTime? endDate;
  final RecurrenceType recurrence;
  final List<int> weeklyDays; // 1=Mon ... 7=Sun
  final bool status;

  ScheduleConfig({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.startDate,
    required this.recurrence,
    required this.time,
    required this.endDate,
    this.weeklyDays = const [],
    this.status = false,
  });

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) {
    return ScheduleConfig(
      id: json['id'],
      name: json['name'],
      colorHex: json['colorHex'],
      startDate: DateTime.parse(json['startDate']),
      time: DateTime.parse(json['time']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.name == json['recurrence'],
      ),
      status: json['status'] ?? false,
      weeklyDays: List<int>.from(json['weeklyDays'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'startDate': startDate.toIso8601String(),
      'time': time.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'recurrence': recurrence.name,
      'weeklyDays': weeklyDays,
      'status': status,
    };
  }

  ScheduleConfig copyWith({
    String? id,
    String? name,
    String? colorHex,
    DateTime? startDate,
    DateTime? time,
    DateTime? endDate,
    RecurrenceType? recurrence,
    List<int>? weeklyDays,
    bool? status,
  }) {
    return ScheduleConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      startDate: startDate ?? this.startDate,
      time: time ?? this.time,
      endDate: endDate ?? this.endDate,
      recurrence: recurrence ?? this.recurrence,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      status: status ?? this.status,
    );
  }

  /// Returns a cron expression based on [recurrence], [time], [startDate], and [weeklyDays].
  ///
  /// Format: `minute hour day-of-month month day-of-week`
  ///
  /// - [RecurrenceType.none]   → `min hour day month *`  (runs once on startDate)
  /// - [RecurrenceType.daily]  → `min hour * * *`
  /// - [RecurrenceType.weekly] → `min hour * * mon,tue,...` (weeklyDays 1=Mon…7=Sun converted to cron 0=Sun…6=Sat)
  String get cronExpression {
    final minute = time.minute;
    final hour = time.hour;

    switch (recurrence) {
      case RecurrenceType.none:
        // Specific date — run once
        final day = startDate.day;
        final month = startDate.month;
        return '$minute $hour $day $month *';

      case RecurrenceType.daily:
        return '$minute $hour * * *';

      case RecurrenceType.weekly:
        // Convert ISO weekday (1=Mon … 7=Sun) → cron weekday (0=Sun, 1=Mon … 6=Sat)
        final cronDays = weeklyDays.map((d) => d == 7 ? 0 : d).toList()..sort();
        final daysStr = cronDays.isNotEmpty ? cronDays.join(',') : '*';
        return '$minute $hour * * $daysStr';
    }
  }
}
