import 'package:flutter/material.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/core/widgets/main_layout.dart';

enum DashboardTabs {
  dashboard("Dashboard"),
  projects("Projects"),
  devices("Devices"),
  users("Users"),
  roles("Roles"),
  settings("Settings");

  final String title;
  const DashboardTabs(this.title);

  String get route {
    switch (this) {
      case DashboardTabs.dashboard:
        return AppConstants.dashboardRoute;
      case DashboardTabs.projects:
        return AppConstants.projectsRoute;
      case DashboardTabs.devices:
        return AppConstants.devicesRoute;
      case DashboardTabs.users:
        return AppConstants.usersRoute;
      case DashboardTabs.roles:
        return AppConstants.rolesRoute;
      case DashboardTabs.settings:
        return AppConstants.settingsRoute;
    }
  }
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract tab from route name
    DashboardTabs? initialTab;
    switch (settings.name) {
      case AppConstants.dashboardRoute:
        initialTab = DashboardTabs.dashboard;
        break;
      case AppConstants.projectsRoute:
        initialTab = DashboardTabs.projects;
        break;
      case AppConstants.usersRoute:
        initialTab = DashboardTabs.users;
        break;
      case AppConstants.devicesRoute:
        initialTab = DashboardTabs.devices;
        break;
      case AppConstants.rolesRoute:
        initialTab = DashboardTabs.roles;
        break;
      case AppConstants.settingsRoute:
        initialTab = DashboardTabs.settings;
        break;
      default:
        initialTab = DashboardTabs.dashboard;
        break;
    }

    // Always return the same MainLayout, just with different initial tab
    return MaterialPageRoute(
      builder: (_) => MainLayout(initialTab: initialTab),
      settings: settings,
    );
  }
}
