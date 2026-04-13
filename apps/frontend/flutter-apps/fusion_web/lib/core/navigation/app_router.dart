import 'package:flutter/material.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';
import 'package:fusion_web/features/devices/data/models/devices_model.dart';
import 'package:fusion_web/features/devices/presentation/pages/device_detail_page.dart';
import 'package:fusion_web/features/devices/presentation/pages/devices_page.dart';
import 'package:fusion_web/features/organizations/presentation/pages/organizations_page.dart';
import 'package:fusion_web/features/organizations/presentation/pages/organization_profile_page.dart';
import 'package:fusion_web/features/projects/presentation/pages/project_detail_page.dart';
import 'package:fusion_web/features/roles/presentation/pages/roles_page.dart';
import 'package:fusion_web/features/settings/presentation/pages/settings_page.dart';
import 'package:fusion_web/features/users/presentation/pages/user_profile_page.dart';
import 'package:fusion_web/features/users/presentation/pages/users_page.dart';
import 'package:go_router/go_router.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/core/widgets/main_layout.dart';
import 'package:fusion_web/features/auth/presentation/pages/login_page.dart';
import 'package:fusion_web/features/dashboard/presentation/pages/partner_dashboard_page.dart';
import 'package:fusion_web/features/projects/presentation/pages/projects_page.dart';

enum DashboardTabs {
  dashboard("Dashboard"),
  projects("Projects"),
  devices("Devices"),
  users("Users"),
  organizations("Organizations"),
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
      case DashboardTabs.organizations:
        return AppConstants.organizationsRoute;
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
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LoginPage()),
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
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PartnerDashboardPage()),
        ),

        GoRoute(
          path: AppConstants.projectsRoute,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProjectsPage()),
          routes: [
            GoRoute(
              path: ':id',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                return NoTransitionPage(
                  child: ProjectDetailPage(projectId: id),
                );
              },
              routes: [
                GoRoute(
                  path: AppConstants.devicesRoute + "/:deviceId",
                  pageBuilder: (context, state) {
                    final device = state.extra as Device;

                    return NoTransitionPage(
                      child: DeviceDetailPage(device: device),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        //         GoRoute(
        //   path: '${AppConstants.projectsRoute}/:id',
        //   pageBuilder: (context, state) {
        //     final id = state.pathParameters['id']!;
        //     return NoTransitionPage(
        //       child: ProjectDetailPage(projectId: id),
        //     );
        //   },
        // ),
        GoRoute(
          path: AppConstants.devicesRoute,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DevicesPage()),
          routes: [
            GoRoute(
              name: 'device_detail',
              path: ':deviceId',
              pageBuilder: (context, state) {
                final device = state.extra as Device;

                return NoTransitionPage(
                  child: DeviceDetailPage(device: device),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: AppConstants.usersRoute,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: UsersPage()),
        ),

        GoRoute(
          path: AppConstants.organizationsRoute,
          builder: (_, __) => const OrganizationsPage(),
        ),

        GoRoute(
          path: AppConstants.organizationsRoute,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: OrganizationsPage()),
        ),

        GoRoute(
          path: AppConstants.rolesRoute,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: RolesPage()),
        ),
        GoRoute(
          path: AppConstants.settingsRoute,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsPage()),
        ),

        GoRoute(
          path: '/users/:id',
          pageBuilder: (context, state) {
            final user = state.extra as UserEntity;

            return MaterialPage(child: UserProfilePage(user: user));
          },
        ),
      ],
    ),
  ],
);

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
  if (path.startsWith(AppConstants.organizationsRoute)) {
    return DashboardTabs.organizations;
  }
  if (path.startsWith(AppConstants.rolesRoute)) {
    return DashboardTabs.roles;
  }
  if (path.startsWith(AppConstants.settingsRoute)) {
    return DashboardTabs.settings;
  }
  return DashboardTabs.dashboard;
}
