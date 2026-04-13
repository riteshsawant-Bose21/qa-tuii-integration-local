import 'package:flutter/material.dart';
import 'package:fusion_app/features/notification/presentation/notification_all_tab.dart';
import 'package:fusion_app/features/notification/presentation/notification_critical_tab.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/tab_switcher.dart';
import 'package:fusion_lib/fusion_lib.dart';

enum NotificationTab { all, critical }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  NotificationTab _selectedTab = NotificationTab.all;
  
  @override
  initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Notifications'),
        body: Column(
          children: [
            CommonTabSwitcher<NotificationTab>(
              values: NotificationTab.values,
              initialValue: NotificationTab.all,
              labelBuilder: (tab) {
                switch (tab) {
                  case NotificationTab.all:
                    return "All Notifications";
                  case NotificationTab.critical:
                    return "Critical";
                }
              },
              onChanged: (tab) {
                print("Selected: $tab");
                setState(() {
                  _selectedTab = tab;
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildTabContent())
          ],
        )
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case NotificationTab.all:
        return  NotificationsAllTab();
      case NotificationTab.critical:
        return  NotificationsCriticalTab();
    }
  }

}






