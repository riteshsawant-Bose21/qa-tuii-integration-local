enum DeviceAlertType { none, critical, warning }

class DeviceModel {
  final String title;
  final String subtitle;
  final String temperature;
  final int cpu;
  final int disk;
  final DeviceAlertType alertType;
  final String alertText;

  const DeviceModel({
    required this.title,
    required this.subtitle,
    required this.temperature,
    required this.cpu,
    required this.disk,
    this.alertType = DeviceAlertType.none,
    this.alertText = '',
  });
}
