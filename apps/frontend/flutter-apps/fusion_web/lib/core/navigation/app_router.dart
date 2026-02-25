// import 'package:flutter/material.dart';
// import 'package:fusion_web/core/constants/app_constants.dart';
// import 'package:fusion_web/core/widgets/main_layout.dart';
// import 'package:fusion_web/features/auth/presentation/pages/login_page.dart';
// import 'package:fusion_web/features/projects/data/models/project_model.dart';
// import 'package:fusion_web/features/projects/presentation/pages/project_detail_page.dart';

// enum DashboardTabs {
//   dashboard("Dashboard"),
//   projects("Projects"),
//   devices("Devices"),
//   users("Users"),
//   roles("Roles"),
//   settings("Settings");

//   final String title;
//   const DashboardTabs(this.title);

//   String get route {
//     switch (this) {
//       case DashboardTabs.dashboard:
//         return AppConstants.dashboardRoute;
//       case DashboardTabs.projects:
//         return AppConstants.projectsRoute;
//       case DashboardTabs.devices:
//         return AppConstants.devicesRoute;
//       case DashboardTabs.users:
//         return AppConstants.usersRoute;
//       case DashboardTabs.roles:
//         return AppConstants.rolesRoute;
//       case DashboardTabs.settings:
//         return AppConstants.settingsRoute;
//     }
//   }
// }

// class AppRouter {
//   static Route<dynamic> generateRoute(RouteSettings settings) {

//     // LOGIN
//     if (settings.name == AppConstants.loginRoute) {
//       return MaterialPageRoute(
//         builder: (_) => const LoginPage(),
//         settings: settings,
//       );
//     }

//     // PROJECT DETAILS
//     if (settings.name != null &&
//         settings.name!.startsWith('${AppConstants.projectsRoute}/')) {

//       final uri = Uri.parse(settings.name!);
//       final projectId = uri.pathSegments.last;

//       final args = settings.arguments as Map<String, dynamic>?;

//       final project = args?['project'];
//       final viewModel = args?['viewModel'];

//       return MaterialPageRoute(
//         builder: (_) => MainLayout(
//           initialTab: DashboardTabs.projects,
//           child: ProjectDetailPage(
//             project: project,
//             viewModel: viewModel,
//           ),
//         ),
//         settings: settings,
//       );
//     }

//     // NORMAL TABS
//     DashboardTabs initialTab;

//     switch (settings.name) {
//       case AppConstants.dashboardRoute:
//         initialTab = DashboardTabs.dashboard;
//         break;
//       case AppConstants.projectsRoute:
//         initialTab = DashboardTabs.projects;
//         break;
//       default:
//         initialTab = DashboardTabs.dashboard;
//     }

//     return MaterialPageRoute(
//       builder: (_) => MainLayout(initialTab: initialTab),
//       settings: settings,
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:fusion_web/features/devices/presentation/pages/devices_page.dart';
import 'package:fusion_web/features/roles/presentation/pages/roles_page.dart';
import 'package:fusion_web/features/settings/presentation/pages/settings_page.dart';
import 'package:fusion_web/features/users/presentation/pages/users_page.dart';
import 'package:go_router/go_router.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/core/widgets/main_layout.dart';
import 'package:fusion_web/features/auth/presentation/pages/login_page.dart';
import 'package:fusion_web/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fusion_web/features/projects/presentation/pages/projects_page.dart';

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

final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.dashboardRoute,
  routes: [
    // LOGIN (outside shell)
    GoRoute(
      path: AppConstants.loginRoute,
      builder: (context, state) => const LoginPage(),
    ),

    // SHELL ROUTE
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(
          initialTab: _getInitialTab(state.uri.path),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: AppConstants.dashboardRoute,
          builder: (_, __) => const DashboardPage(),
        ),

        GoRoute(
          path: AppConstants.projectsRoute,
          builder: (_, __) => const ProjectsPage(),
        ),

        GoRoute(
          path: AppConstants.devicesRoute,
          builder: (_, __) => const DevicesPage(),
        ),

        GoRoute(
          path: AppConstants.usersRoute,
          builder: (_, __) => const UsersPage(),
        ),

        GoRoute(
          path: AppConstants.rolesRoute,
          builder: (_, __) => const RolesPage(),
        ),

        GoRoute(
          path: AppConstants.settingsRoute,
          builder: (_, __) => const SettingsPage(),
        ),
      ],
    ),
  ],
);

// DashboardTabs _getInitialTab(String path) {
//   if (path.startsWith(AppConstants.projectsRoute)) {
//     return DashboardTabs.projects;
//   }
//   return DashboardTabs.dashboard;
// }

DashboardTabs _getInitialTab(String path) {
  if (path.startsWith(AppConstants.projectsRoute)) {
    return DashboardTabs.projects;
  }
  if (path.startsWith(AppConstants.devicesRoute)) {
    return DashboardTabs.devices;
  }
  if (path.startsWith(AppConstants.usersRoute)) {
    return DashboardTabs.users;
  }
  if (path.startsWith(AppConstants.rolesRoute)) {
    return DashboardTabs.roles;
  }
  if (path.startsWith(AppConstants.settingsRoute)) {
    return DashboardTabs.settings;
  }
  return DashboardTabs.dashboard;
}