enum RecurrenceType {
  none,
  daily,
  weekly,
}

class ScheduleConfig {
  final String id;
  final String name;
  final String colorHex;
  final DateTime startDateTime;
  final RecurrenceType recurrence;
  final List<int> weeklyDays; // 1=Mon ... 7=Sun
  final bool status;

  ScheduleConfig({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.startDateTime,
    required this.recurrence,
    this.weeklyDays = const [],
    this.status = false,
  });

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) {
    return ScheduleConfig(
      id: json['id'],
      name: json['name'],
      colorHex: json['colorHex'],
      startDateTime: DateTime.parse(json['startDateTime']),
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
      'startDateTime': startDateTime.toIso8601String(),
      'recurrence': recurrence.name,
      'weeklyDays': weeklyDays,
      'status': status,
    };
  }

  ScheduleConfig copyWith({
    String? id,
    String? name,
    String? colorHex,
    DateTime? startDateTime,
    RecurrenceType? recurrence,
    List<int>? weeklyDays,
  }) {
    return ScheduleConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      startDateTime: startDateTime ?? this.startDateTime,
      recurrence: recurrence ?? this.recurrence,
      weeklyDays: weeklyDays ?? this.weeklyDays,
    );
  }
}
