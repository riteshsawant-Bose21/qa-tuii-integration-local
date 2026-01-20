import 'package:flutter/material.dart';
import 'package:fusion_web/core/widgets/fusion_sidebar.dart';
import 'package:fusion_web/core/navigation/app_router.dart';
import 'package:fusion_web/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fusion_web/features/projects/presentation/pages/projects_page.dart';
import 'package:fusion_web/features/users/presentation/pages/users_page.dart';
import 'package:fusion_web/features/devices/presentation/pages/devices_page.dart';
import 'package:fusion_web/features/roles/presentation/pages/roles_page.dart';
import 'package:fusion_web/features/settings/presentation/pages/settings_page.dart';

class MainLayout extends StatefulWidget {
  final DashboardTabs? initialTab;

  const MainLayout({super.key, this.initialTab});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late DashboardTabs _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab ?? DashboardTabs.dashboard;
  }

  Widget _getScreenForTab(DashboardTabs tab) {
    switch (tab) {
      case DashboardTabs.dashboard:
        return const DashboardPage();
      case DashboardTabs.projects:
        return const ProjectsPage();
      case DashboardTabs.users:
        return const UsersPage();
      case DashboardTabs.devices:
        return const DevicesPage();
      case DashboardTabs.roles:
        return const RolesPage();
      case DashboardTabs.settings:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // Global Sidebar - always visible
          FusionSidebar(
            selectedTab: _currentTab,
            onTabChanged: (tab) {
              setState(() {
                _currentTab = tab;
              });
            },
          ),
          // Content area - shows different pages
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _getScreenForTab(_currentTab),
            ),
          ),
        ],
      ),
    );
  }
}
