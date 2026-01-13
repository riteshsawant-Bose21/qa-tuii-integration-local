import 'package:flutter/material.dart';
import 'package:fusion_web/core/widgets/fusion_sidebar.dart';

enum DashboardTabs {
  dashboard("Dashboard"),
  projects("Projects"),
  devices("Devices"),
  users("Users"),
  settings("Settings");

  final String title;
  const DashboardTabs(this.title);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ValueNotifier<DashboardTabs> _currentTabNotifier =
      ValueNotifier<DashboardTabs>(DashboardTabs.dashboard);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ValueListenableBuilder<DashboardTabs>(
                  valueListenable: _currentTabNotifier,
                  builder:
                      (
                        BuildContext context,
                        DashboardTabs selectedTab,
                        Widget? child,
                      ) {
                        return FusionSidebar(
                          selectedTab: selectedTab,
                          onTabChanged: (DashboardTabs newTab) {
                            _currentTabNotifier.value = newTab;
                          },
                        );
                      },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
