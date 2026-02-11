import 'package:flutter/material.dart';
import 'package:fusion_web/core/widgets/fusion_sidebar.dart';
import 'package:fusion_web/core/navigation/app_router.dart';
import 'package:fusion_web/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fusion_web/features/projects/presentation/pages/projects_page.dart';
import 'package:fusion_web/features/users/presentation/pages/users_page.dart';
import 'package:fusion_web/features/devices/presentation/pages/devices_page.dart';
import 'package:fusion_web/features/roles/presentation/pages/roles_page.dart';
import 'package:fusion_web/features/settings/presentation/pages/settings_page.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/core/constants/app_constants.dart';

class MainLayout extends StatefulWidget {
  final DashboardTabs? initialTab;

  const MainLayout({super.key, this.initialTab});

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
    _currentTab = widget.initialTab ?? DashboardTabs.dashboard;
    _checkAuthenticationAndRestoreToken();
  }

  Future<void> _checkAuthenticationAndRestoreToken() async {
    try {
      // Use the existing AuthViewModel from ServiceLocator to check auth and restore token
      final authViewModel = ServiceLocator().authViewModel;

      // Check authentication status and restore token if logged in
      await authViewModel.checkAuthStatus();

      setState(() {
        _isAuthenticated = authViewModel.isLoggedIn;
        _isAuthChecking = false;
      });

      if (!_isAuthenticated) {
        _redirectToLogin();
      } else {
        print('🔐 Authentication verified and token restored in MainLayout');
      }
    } catch (e) {
      print('⚠️ Auth check failed in MainLayout: $e');
      setState(() {
        _isAuthChecking = false;
        _isAuthenticated = false;
      });
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      setState(() {
        _isAuthChecking = false;
        _isAuthenticated = false;
      });

      // Use pushNamedAndRemoveUntil to clear the navigation stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppConstants.loginRoute,
        (route) => false,
      );
    }
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
    if (_isAuthChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Verifying authentication...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Text(
            'Redirecting to login...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

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
