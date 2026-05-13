import 'package:flutter/foundation.dart';
import 'package:fusion_web/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fusion_web/features/dashboard/domain/usecases/dashboard_usecases.dart';

/// Dashboard view model for managing dashboard state and business logic
class DashboardViewModel extends ChangeNotifier {
  final GetPartnerDashboardUseCase _getPartnerDashboardUseCase;
  final GetProjectOverviewUseCase _getProjectOverviewUseCase;
  final GetDeviceHealthSummaryUseCase _getDeviceHealthSummaryUseCase;
  final GetIncidentSnapshotUseCase _getIncidentSnapshotUseCase;
  final GetRegionalInsightsUseCase _getRegionalInsightsUseCase;
  final GetUsersOverviewUseCase _getUsersOverviewUseCase;

  DashboardViewModel({
    required GetPartnerDashboardUseCase getPartnerDashboardUseCase,
    required GetProjectOverviewUseCase getProjectOverviewUseCase,
    required GetDeviceHealthSummaryUseCase getDeviceHealthSummaryUseCase,
    required GetIncidentSnapshotUseCase getIncidentSnapshotUseCase,
    required GetRegionalInsightsUseCase getRegionalInsightsUseCase,
    required GetUsersOverviewUseCase getUsersOverviewUseCase,
  }) : _getPartnerDashboardUseCase = getPartnerDashboardUseCase,
       _getProjectOverviewUseCase = getProjectOverviewUseCase,
       _getDeviceHealthSummaryUseCase = getDeviceHealthSummaryUseCase,
       _getIncidentSnapshotUseCase = getIncidentSnapshotUseCase,
       _getRegionalInsightsUseCase = getRegionalInsightsUseCase,
       _getUsersOverviewUseCase = getUsersOverviewUseCase;

  // State variables
  DashboardEntity? _dashboard;
  ProjectOverviewEntity? _projectOverview;
  DeviceHealthSummaryEntity? _deviceHealthSummary;
  IncidentSnapshotEntity? _incidentSnapshot;
  RegionalInsightsEntity? _regionalInsights;
  UsersOverviewEntity? _usersOverview;

  bool _isLoading = false;
  String? _error;
  bool _isRefreshing = false;

  // Getters
  DashboardEntity? get dashboard => _dashboard;
  ProjectOverviewEntity? get projectOverview => _projectOverview;
  DeviceHealthSummaryEntity? get deviceHealthSummary => _deviceHealthSummary;
  IncidentSnapshotEntity? get incidentSnapshot => _incidentSnapshot;
  RegionalInsightsEntity? get regionalInsights => _regionalInsights;
  UsersOverviewEntity? get usersOverview => _usersOverview;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRefreshing => _isRefreshing;
  bool get hasData => _dashboard != null;

  /// Initialize dashboard data
  Future<void> initialize() async {
    await loadDashboard();
  }

  /// Load complete dashboard data
  Future<void> loadDashboard() async {
    _setLoading(true);
    _clearError();

    try {
      final dashboardData = await _getPartnerDashboardUseCase();
      _dashboard = dashboardData;
      _projectOverview = dashboardData.projectOverview;
      _deviceHealthSummary = dashboardData.deviceHealthSummary;
      _incidentSnapshot = dashboardData.incidentSnapshot;
      _regionalInsights = dashboardData.regionalInsights;
      _usersOverview = dashboardData.usersOverview;

      print('✅ Dashboard data loaded successfully');
      print('- Total Projects: ${_projectOverview?.totalProjects}');
      print('- Total Devices: ${_deviceHealthSummary?.totalDevices}');
      print('- Open Incidents: ${_incidentSnapshot?.totalOpenIncidents}');
    } catch (e) {
      _setError('Failed to load dashboard data: ${e.toString()}');
      print('❌ Dashboard loading failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      await loadDashboard();
      print('🔄 Dashboard data refreshed');
    } catch (e) {
      print('❌ Dashboard refresh failed: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Load individual project overview
  Future<void> loadProjectOverview() async {
    try {
      _projectOverview = await _getProjectOverviewUseCase();
      notifyListeners();
    } catch (e) {
      print('❌ Failed to load project overview: $e');
    }
  }

  /// Load individual device health summary
  Future<void> loadDeviceHealthSummary() async {
    try {
      _deviceHealthSummary = await _getDeviceHealthSummaryUseCase();
      notifyListeners();
    } catch (e) {
      print('❌ Failed to load device health summary: $e');
    }
  }

  /// Load individual incident snapshot
  Future<void> loadIncidentSnapshot() async {
    try {
      _incidentSnapshot = await _getIncidentSnapshotUseCase();
      notifyListeners();
    } catch (e) {
      print('❌ Failed to load incident snapshot: $e');
    }
  }

  /// Load individual regional insights
  Future<void> loadRegionalInsights() async {
    try {
      _regionalInsights = await _getRegionalInsightsUseCase();
      notifyListeners();
    } catch (e) {
      print('❌ Failed to load regional insights: $e');
    }
  }

  /// Load individual users overview
  Future<void> loadUsersOverview() async {
    try {
      _usersOverview = await _getUsersOverviewUseCase();
      notifyListeners();
    } catch (e) {
      print('❌ Failed to load users overview: $e');
    }
  }

  /// Clear error state
  void clearError() {
    _clearError();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
