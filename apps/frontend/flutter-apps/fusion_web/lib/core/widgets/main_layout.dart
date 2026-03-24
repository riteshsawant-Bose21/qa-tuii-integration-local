import 'package:flutter/material.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/core/navigation/app_router.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/core/widgets/fusion_sidebar.dart';
import 'package:fusion_web/features/dashboard/presentation/pages/partner_dashboard_page.dart';
import 'package:fusion_web/features/devices/presentation/pages/devices_page.dart';
import 'package:fusion_web/features/organizations/presentation/pages/organizations_page.dart';
import 'package:fusion_web/features/projects/presentation/pages/projects_page.dart';
import 'package:fusion_web/features/roles/presentation/pages/roles_page.dart';
import 'package:fusion_web/features/settings/presentation/pages/settings_page.dart';
import 'package:fusion_web/features/users/presentation/pages/users_page.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatefulWidget {
  final DashboardTabs initialTab;
  final Widget? child;

  const MainLayout({super.key, required this.initialTab, this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late DashboardTabs _currentTab;

  bool _isAuthChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _checkAuthenticationAndRestoreToken();
  }

  @override
  void didUpdateWidget(covariant MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialTab != widget.initialTab) {
      setState(() {
        _currentTab = widget.initialTab;
      });
    }
  }

  Future<void> _checkAuthenticationAndRestoreToken() async {
    try {
      print('MainLayout: Starting auth check...');
      print('MainLayout: Current URL: ${Uri.base.toString()}');

      // Give Auth0 SDK significant time to initialize and restore session
      // This is critical for session persistence across page refreshes
      await Future.delayed(const Duration(milliseconds: 1500));

      final authViewModel = ServiceLocator().authViewModel;

      print('MainLayout: Calling authViewModel.checkAuthStatus()...');
      await authViewModel.checkAuthStatus();

      setState(() {
        _isAuthenticated = authViewModel.isLoggedIn;
        _isAuthChecking = false;
      });

      print(
        'MainLayout: Auth check complete, isAuthenticated: $_isAuthenticated',
      );
      print(
        'MainLayout: Current user: ${authViewModel.currentUser?.email ?? "null"}',
      );
      print('MainLayout: Auth error: ${authViewModel.error ?? "none"}');

      if (!_isAuthenticated) {
        print('MainLayout: User not authenticated, redirecting to login');
        _redirectToLogin();
      } else {
        print('MainLayout: User authenticated, staying on current page');
      }
    } catch (e) {
      print('MainLayout: Auth check error: $e');
      setState(() {
        _isAuthChecking = false;
        _isAuthenticated = false;
      });
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      context.go(AppConstants.loginRoute);
    }
  }

  Widget _getScreenForTab(DashboardTabs tab) {
    switch (tab) {
      case DashboardTabs.dashboard:
        return const PartnerDashboardPage();
      case DashboardTabs.projects:
        return const ProjectsPage();
      case DashboardTabs.devices:
        return const DevicesPage();
      case DashboardTabs.users:
        return const UsersPage();
      case DashboardTabs.organizations:
        return const OrganizationsPage();
      case DashboardTabs.roles:
        return const RolesPage();
      case DashboardTabs.settings:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: Row(
        children: [
          // FusionSidebar(
          //   selectedTab: _currentTab,
          //   onTabChanged: (tab) {
          //     Navigator.pushReplacementNamed(context, tab.route);
          //   },
          // ),
          FusionSidebar(
            selectedTab: _currentTab,
            onTabChanged: (tab) {
              context.go(tab.route);
            },
          ),
          Expanded(child: widget.child ?? _getScreenForTab(_currentTab)),
        ],
      ),
    );
  }
}
