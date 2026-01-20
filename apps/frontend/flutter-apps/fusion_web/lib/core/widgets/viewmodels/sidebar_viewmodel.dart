import 'package:flutter/foundation.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/core/navigation/app_router.dart';

class SidebarViewModel extends BaseViewModel {
  DashboardTabs? _selectedTab;
  String _userName = 'Sujith Devadas';
  String _appName = 'Fusion Web';
  bool _hasNotifications = true;

  DashboardTabs? get selectedTab => _selectedTab;
  String get userName => _userName;
  String get appName => _appName;
  bool get hasNotifications => _hasNotifications;

  void setSelectedTab(DashboardTabs? tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }

  void updateUserInfo({String? name, String? app}) {
    bool changed = false;

    if (name != null && _userName != name) {
      _userName = name;
      changed = true;
    }

    if (app != null && _appName != app) {
      _appName = app;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void toggleNotifications() {
    _hasNotifications = !_hasNotifications;
    notifyListeners();
  }

  void clearNotifications() {
    _hasNotifications = false;
    notifyListeners();
  }

  void signOut() {
    // Handle sign out logic
    // This would typically involve:
    // 1. Clear user session
    // 2. Navigate to login screen
    // 3. Clear cached data
    debugPrint('Sign out requested');
  }

  void initialize() {
    // Set initial loaded state
    setLoaded(_selectedTab);
  }
}
