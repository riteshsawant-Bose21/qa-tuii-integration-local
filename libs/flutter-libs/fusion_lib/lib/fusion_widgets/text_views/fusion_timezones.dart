// ignore_for_file: constant_identifier_names

enum FusionTimeZones {
  IST('India Standard Time', 330),
  UTC('Coordinated Universal Time', 0),
  EST('Eastern Standard Time', -300),
  CST('Central Standard Time (US)', -360),
  PST('Pacific Standard Time', -480),
  CET('Central European Time', 60),
  JST('Japan Standard Time', 540);

  const FusionTimeZones(this.label, this.offsetMinutes);

  final String label;
  final int offsetMinutes;

  /// Example: UTC+05:30
  String get utcOffsetString {
    final sign = offsetMinutes >= 0 ? '+' : '-';
    final abs = offsetMinutes.abs();
    final hours = (abs ~/ 60).toString().padLeft(2, '0');
    final minutes = (abs % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$minutes';
  }

  static FusionTimeZones? fromString(String? value) {
    try {
      return FusionTimeZones.values.firstWhere((FusionTimeZones element) => element.name == value);
    } catch (e) {
      return null;
    }
  }

  static FusionTimeZones? fromJson(String? json) {
    try {
      return FusionTimeZones.values.firstWhere((FusionTimeZones element) => element.name == json);
    } catch (e) {
      return null;
    }
  }

  // toJson.
  String toJson() => name;
}
