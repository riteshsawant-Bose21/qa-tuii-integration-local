import 'package:fusion_web/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fusion_web/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Get partner dashboard use case
class GetPartnerDashboardUseCase {
  final DashboardRepository _repository;

  const GetPartnerDashboardUseCase(this._repository);

  Future<DashboardEntity> call() async {
    return await _repository.getPartnerDashboard();
  }
}

/// Get project overview use case
class GetProjectOverviewUseCase {
  final DashboardRepository _repository;

  const GetProjectOverviewUseCase(this._repository);

  Future<ProjectOverviewEntity> call() async {
    return await _repository.getProjectOverview();
  }
}

/// Get device health summary use case
class GetDeviceHealthSummaryUseCase {
  final DashboardRepository _repository;

  const GetDeviceHealthSummaryUseCase(this._repository);

  Future<DeviceHealthSummaryEntity> call() async {
    return await _repository.getDeviceHealthSummary();
  }
}

/// Get incident snapshot use case
class GetIncidentSnapshotUseCase {
  final DashboardRepository _repository;

  const GetIncidentSnapshotUseCase(this._repository);

  Future<IncidentSnapshotEntity> call() async {
    return await _repository.getIncidentSnapshot();
  }
}

/// Get regional insights use case
class GetRegionalInsightsUseCase {
  final DashboardRepository _repository;

  const GetRegionalInsightsUseCase(this._repository);

  Future<RegionalInsightsEntity> call() async {
    return await _repository.getRegionalInsights();
  }
}

/// Get users overview use case
class GetUsersOverviewUseCase {
  final DashboardRepository _repository;

  const GetUsersOverviewUseCase(this._repository);

  Future<UsersOverviewEntity> call() async {
    return await _repository.getUsersOverview();
  }
}
