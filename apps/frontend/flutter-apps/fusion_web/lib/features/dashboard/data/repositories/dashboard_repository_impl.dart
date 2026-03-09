import 'package:fusion_web/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fusion_web/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:fusion_web/features/dashboard/data/datasources/dashboard_datasource.dart';

/// Dashboard repository implementation
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardDataSource _dataSource;

  const DashboardRepositoryImpl({required DashboardDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<DashboardEntity> getPartnerDashboard() async {
    try {
      final dashboardModel = await _dataSource.getPartnerDashboard();
      return dashboardModel.toEntity();
    } catch (e) {
      throw Exception('Repository: Failed to get partner dashboard: $e');
    }
  }

  @override
  Future<ProjectOverviewEntity> getProjectOverview() async {
    try {
      final projectOverviewModel = await _dataSource.getProjectOverview();
      return projectOverviewModel.toEntity();
    } catch (e) {
      throw Exception('Repository: Failed to get project overview: $e');
    }
  }

  @override
  Future<DeviceHealthSummaryEntity> getDeviceHealthSummary() async {
    try {
      final deviceHealthModel = await _dataSource.getDeviceHealthSummary();
      return deviceHealthModel.toEntity();
    } catch (e) {
      throw Exception('Repository: Failed to get device health summary: $e');
    }
  }

  @override
  Future<IncidentSnapshotEntity> getIncidentSnapshot() async {
    try {
      final incidentSnapshotModel = await _dataSource.getIncidentSnapshot();
      return incidentSnapshotModel.toEntity();
    } catch (e) {
      throw Exception('Repository: Failed to get incident snapshot: $e');
    }
  }

  @override
  Future<RegionalInsightsEntity> getRegionalInsights() async {
    try {
      final regionalInsightsModel = await _dataSource.getRegionalInsights();
      return regionalInsightsModel.toEntity();
    } catch (e) {
      throw Exception('Repository: Failed to get regional insights: $e');
    }
  }

  @override
  Future<UsersOverviewEntity> getUsersOverview() async {
    try {
      final usersOverviewModel = await _dataSource.getUsersOverview();
      return usersOverviewModel.toEntity();
    } catch (e) {
      throw Exception('Repository: Failed to get users overview: $e');
    }
  }
}
