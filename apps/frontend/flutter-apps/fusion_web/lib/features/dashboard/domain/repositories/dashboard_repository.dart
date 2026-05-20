import 'package:fusion_web/features/dashboard/domain/entities/dashboard_entities.dart';

/// Dashboard repository interface
abstract class DashboardRepository {
  /// Get dashboard data for partner view
  Future<DashboardEntity> getPartnerDashboard();

  /// Get project overview for partner
  Future<ProjectOverviewEntity> getProjectOverview();

  /// Get device health summary for partner
  Future<DeviceHealthSummaryEntity> getDeviceHealthSummary();

  /// Get incident snapshot for partner
  Future<IncidentSnapshotEntity> getIncidentSnapshot();

  /// Get regional insights for partner
  Future<RegionalInsightsEntity> getRegionalInsights();

  /// Get users overview for partner
  Future<UsersOverviewEntity> getUsersOverview();
}
