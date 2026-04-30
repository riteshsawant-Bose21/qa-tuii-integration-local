class AppNotification {
  final NotificationType type;
  final String timeLabel;
  final String title;
  final String zone;
  final String device;
  final String location;
  final DateTime dateTime;

  const AppNotification({
    required this.type,
    required this.timeLabel,
    required this.title,
    required this.zone,
    required this.device,
    required this.location,
    required this.dateTime,
  });
}

enum NotificationType {
  critical,
  warning,
  neutral,
}

class NotificationModel {
  final String? label;
  final List<AppNotification> notification;

  const NotificationModel({
    this.label,
    this.notification = const[],
  });
}