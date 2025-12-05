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
  final DateTime endDate;
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
      endDate: DateTime.parse(json['endDate']),
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
      'endDate': endDate.toIso8601String(),
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
    );
  }
}
