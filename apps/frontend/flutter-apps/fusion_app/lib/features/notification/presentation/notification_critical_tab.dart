import 'package:flutter/material.dart';
import 'package:fusion_app/features/notification/models/notification_model.dart';
import 'package:fusion_app/features/notification/widgets/empty_view.dart';
import 'package:fusion_app/features/notification/widgets/header_section.dart' show NotificationHeaderSection;
import 'package:fusion_app/features/notification/widgets/notification_item_card.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/empty_state.dart';
import 'package:intl/intl.dart';
import 'package:fusion_lib/fusion_lib.dart';

class NotificationsCriticalTab extends StatefulWidget {
  const NotificationsCriticalTab({super.key});

  @override
  State<NotificationsCriticalTab> createState() => _NotificationsCriticalTabState();
}

class _NotificationsCriticalTabState extends State<NotificationsCriticalTab> {
  final List<AppNotification> notifications = [
    AppNotification(
      type: NotificationType.critical,
      timeLabel: 'Just now',
      title: 'Open Circuit Fault Channel',
      zone: 'Zone: Reception, Circuit: DM5SE',
      device: 'Powersmart 8300',
      location: 'Reception',
      dateTime: DateTime.now(),
    ),
    AppNotification(
      type: NotificationType.critical,
      timeLabel: '5h ago',
      title: 'Open Circuit Fault Channel',
      zone: 'Zone: Reception, Circuit: DM5SE',
      device: 'Powersmart 8300',
      location: 'Reception',
      dateTime: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AppNotification(
      type: NotificationType.critical,
      timeLabel: '10:00 PM',
      title: 'Impedance Warning',
      zone: 'Zone: Lobby, Circuit: DM2',
      device: 'Powersmart 8300',
      location: 'Lobby',
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
    ),
    AppNotification(
      type: NotificationType.critical,
      timeLabel: '9:00 PM',
      title: 'Impedance Warning',
      zone: 'Zone: Lobby, Circuit: DM2',
      device: 'Powersmart 8300',
      location: 'Lobby',
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    AppNotification(
      type: NotificationType.critical,
      timeLabel: '11:00 AM',
      title: 'System Check Completed',
      zone: 'All zones operational',
      device: 'Powersmart 8300',
      location: 'System',
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 10)),
    ),
    AppNotification(
      type: NotificationType.critical,
      timeLabel: 'Just now',
      title: 'Amplifier Overload',
      zone: 'Zone: Conference Room',
      device: 'Powersmart 8500',
      location: 'Conference Room',
      dateTime: DateTime.now().subtract(const Duration(days: 10, hours: 10)),
    ),
    AppNotification(
      type: NotificationType.critical,
      timeLabel: '9:00 PM',
      title: 'Voltage Fluctuation',
      zone: 'Zone: Parking Area',
      device: 'Powersmart 8200',
      location: 'Parking',
      dateTime: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
    ),
  ];


  List<NotificationModel> groupedNotifications = [];
  @override
  initState(){
    super.initState();

    groupedNotifications = groupNotificationsByDate(notifications);
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {

    if(groupedNotifications.isEmpty){
      return CommonEmptyState(
        icon: Icons.notifications_none_outlined,
        title: "No Notifications Yet",
        subtitle:
        "You're all caught up! We'll notify you when there's something new",
      );
    }


    return ListView.builder(
      itemCount: groupedNotifications.length,
      itemBuilder: (BuildContext context, int i){

        final items = groupedNotifications[i].notification;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ...items.expand((notification) => [
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: NotificationCard(
                  data: notification,
                ),
              ),
            ]),
          ],
        );
      },
      padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
    );
  }

  String getSectionTitle(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final d = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';

    return DateFormat('MMM d, yyyy').format(d);
  }

  List<NotificationModel> groupNotificationsByDate(
      List<AppNotification> notifications,
      ) {
    // 1️⃣ Sort newest first
    final sorted = [...notifications]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // 2️⃣ Group by formatted date
    final Map<String, List<AppNotification>> grouped = {};

    for (final notification in sorted) {
      final label = getSectionTitle(notification.dateTime);

      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(notification);
    }

    // 3️⃣ Preserve chronological order
    final List<NotificationModel> result = [];

    for (final entry in grouped.entries) {
      result.add(
        NotificationModel(
          label: entry.key,
          notification: entry.value,
        ),
      );
    }

    return result;
  }




}






