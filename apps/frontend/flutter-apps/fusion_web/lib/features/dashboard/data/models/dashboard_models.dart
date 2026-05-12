import 'package:fusion_web/features/dashboard/domain/entities/dashboard_entities.dart';

/// Project overview model
class ProjectOverviewModel {
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final int archivedProjects;
  final Map<String, int> projectsByRegion;
  final int recentActivityCount7Days;
  final int recentActivityCount30Days;

  const ProjectOverviewModel({
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.archivedProjects,
    required this.projectsByRegion,
    required this.recentActivityCount7Days,
    required this.recentActivityCount30Days,
  });

  factory ProjectOverviewModel.fromJson(Map<String, dynamic> json) {
    return ProjectOverviewModel(
      totalProjects: json['total_projects'] as int? ?? 0,
      activeProjects: json['active_projects'] as int? ?? 0,
      completedProjects: json['completed_projects'] as int? ?? 0,
      archivedProjects: json['archived_projects'] as int? ?? 0,
      projectsByRegion: Map<String, int>.from(
        json['projects_by_region'] as Map<String, dynamic>? ?? {},
      ),
      recentActivityCount7Days: json['recent_activity_7_days'] as int? ?? 0,
      recentActivityCount30Days: json['recent_activity_30_days'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_projects': totalProjects,
      'active_projects': activeProjects,
      'completed_projects': completedProjects,
      'archived_projects': archivedProjects,
      'projects_by_region': projectsByRegion,
      'recent_activity_7_days': recentActivityCount7Days,
      'recent_activity_30_days': recentActivityCount30Days,
    };
  }

  ProjectOverviewEntity toEntity() {
    return ProjectOverviewEntity(
      totalProjects: totalProjects,
      activeProjects: activeProjects,
      completedProjects: completedProjects,
      archivedProjects: archivedProjects,
      projectsByRegion: projectsByRegion,
      recentActivityCount7Days: recentActivityCount7Days,
      recentActivityCount30Days: recentActivityCount30Days,
    );
  }
}

/// Device health summary model
class DeviceHealthSummaryModel {
  final int healthyDevicesCount;
  final int warningDevicesCount;
  final int criticalDevicesCount;
  final Map<String, int> topDeviceModels;
  final int incidentsLast7Days;
  final int incidentsLast30Days;

  const DeviceHealthSummaryModel({
    required this.healthyDevicesCount,
    required this.warningDevicesCount,
    required this.criticalDevicesCount,
    required this.topDeviceModels,
    required this.incidentsLast7Days,
    required this.incidentsLast30Days,
  });

  factory DeviceHealthSummaryModel.fromJson(Map<String, dynamic> json) {
    return DeviceHealthSummaryModel(
      healthyDevicesCount: json['healthy_devices_count'] as int? ?? 0,
      warningDevicesCount: json['warning_devices_count'] as int? ?? 0,
      criticalDevicesCount: json['critical_devices_count'] as int? ?? 0,
      topDeviceModels: Map<String, int>.from(
        json['top_device_models'] as Map<String, dynamic>? ?? {},
      ),
      incidentsLast7Days: json['incidents_last_7_days'] as int? ?? 0,
      incidentsLast30Days: json['incidents_last_30_days'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'healthy_devices_count': healthyDevicesCount,
      'warning_devices_count': warningDevicesCount,
      'critical_devices_count': criticalDevicesCount,
      'top_device_models': topDeviceModels,
      'incidents_last_7_days': incidentsLast7Days,
      'incidents_last_30_days': incidentsLast30Days,
    };
  }

  DeviceHealthSummaryEntity toEntity() {
    return DeviceHealthSummaryEntity(
      healthyDevicesCount: healthyDevicesCount,
      warningDevicesCount: warningDevicesCount,
      criticalDevicesCount: criticalDevicesCount,
      topDeviceModels: topDeviceModels,
      incidentsLast7Days: incidentsLast7Days,
      incidentsLast30Days: incidentsLast30Days,
    );
  }
}

/// Incident trend point model
class IncidentTrendPointModel {
  final DateTime date;
  final int count;

  const IncidentTrendPointModel({required this.date, required this.count});

  factory IncidentTrendPointModel.fromJson(Map<String, dynamic> json) {
    return IncidentTrendPointModel(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'count': count};
  }

  IncidentTrendPoint toEntity() {
    return IncidentTrendPoint(date: date, count: count);
  }
}

/// Incident snapshot model
class IncidentSnapshotModel {
  final int totalOpenIncidents;
  final int criticalAlerts;
  final List<IncidentTrendPointModel> incidentTrendData;
  final Map<String, int> topIncidentCategories;

  const IncidentSnapshotModel({
    required this.totalOpenIncidents,
    required this.criticalAlerts,
    required this.incidentTrendData,
    required this.topIncidentCategories,
  });

  factory IncidentSnapshotModel.fromJson(Map<String, dynamic> json) {
    final trendDataList = json['incident_trend_data'] as List<dynamic>? ?? [];
    final trendData = trendDataList
        .map(
          (data) =>
              IncidentTrendPointModel.fromJson(data as Map<String, dynamic>),
        )
        .toList();

    return IncidentSnapshotModel(
      totalOpenIncidents: json['total_open_incidents'] as int? ?? 0,
      criticalAlerts: json['critical_alerts'] as int? ?? 0,
      incidentTrendData: trendData,
      topIncidentCategories: Map<String, int>.from(
        json['top_incident_categories'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_open_incidents': totalOpenIncidents,
      'critical_alerts': criticalAlerts,
      'incident_trend_data': incidentTrendData
          .map((data) => data.toJson())
          .toList(),
      'top_incident_categories': topIncidentCategories,
    };
  }

  IncidentSnapshotEntity toEntity() {
    return IncidentSnapshotEntity(
      totalOpenIncidents: totalOpenIncidents,
      criticalAlerts: criticalAlerts,
      incidentTrendData: incidentTrendData
          .map((data) => data.toEntity())
          .toList(),
      topIncidentCategories: topIncidentCategories,
    );
  }
}

/// Regional insights model
class RegionalInsightsModel {
  final Map<String, int> projectsByRegion;
  final Map<String, int> activePartnersByRegion;
  final Map<String, int> devicesByGeography;
  final Map<String, double> salesKPIs;

  const RegionalInsightsModel({
    required this.projectsByRegion,
    required this.activePartnersByRegion,
    required this.devicesByGeography,
    required this.salesKPIs,
  });

  factory RegionalInsightsModel.fromJson(Map<String, dynamic> json) {
    return RegionalInsightsModel(
      projectsByRegion: Map<String, int>.from(
        json['projects_by_region'] as Map<String, dynamic>? ?? {},
      ),
      activePartnersByRegion: Map<String, int>.from(
        json['active_partners_by_region'] as Map<String, dynamic>? ?? {},
      ),
      devicesByGeography: Map<String, int>.from(
        json['devices_by_geography'] as Map<String, dynamic>? ?? {},
      ),
      salesKPIs: Map<String, double>.from(
        json['sales_kpis'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projects_by_region': projectsByRegion,
      'active_partners_by_region': activePartnersByRegion,
      'devices_by_geography': devicesByGeography,
      'sales_kpis': salesKPIs,
    };
  }

  RegionalInsightsEntity toEntity() {
    return RegionalInsightsEntity(
      projectsByRegion: projectsByRegion,
      activePartnersByRegion: activePartnersByRegion,
      devicesByGeography: devicesByGeography,
      salesKPIs: salesKPIs,
    );
  }
}

/// Users overview model
class UsersOverviewModel {
  final int totalUsers;
  final int activeUsers;
  final int invitedUsers;
  final int inactiveUsers;
  final Map<String, int> usersByRole;
  final Map<String, int> usersByType;
  final int usersJoinedLast7Days;
  final int usersJoinedLast30Days;
  final DateTime? lastUserJoinedAt;

  const UsersOverviewModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.invitedUsers,
    required this.inactiveUsers,
    required this.usersByRole,
    required this.usersByType,
    required this.usersJoinedLast7Days,
    required this.usersJoinedLast30Days,
    this.lastUserJoinedAt,
  });

  factory UsersOverviewModel.fromJson(Map<String, dynamic> json) {
    return UsersOverviewModel(
      totalUsers: json['total_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      invitedUsers: json['invited_users'] as int? ?? 0,
      inactiveUsers: json['inactive_users'] as int? ?? 0,
      usersByRole: Map<String, int>.from(
        json['users_by_role'] as Map<String, dynamic>? ?? {},
      ),
      usersByType: Map<String, int>.from(
        json['users_by_type'] as Map<String, dynamic>? ?? {},
      ),
      usersJoinedLast7Days: json['users_joined_7_days'] as int? ?? 0,
      usersJoinedLast30Days: json['users_joined_30_days'] as int? ?? 0,
      lastUserJoinedAt: json['last_user_joined_at'] != null
          ? DateTime.parse(json['last_user_joined_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'active_users': activeUsers,
      'invited_users': invitedUsers,
      'inactive_users': inactiveUsers,
      'users_by_role': usersByRole,
      'users_by_type': usersByType,
      'users_joined_7_days': usersJoinedLast7Days,
      'users_joined_30_days': usersJoinedLast30Days,
      'last_user_joined_at': lastUserJoinedAt?.toIso8601String(),
    };
  }

  UsersOverviewEntity toEntity() {
    return UsersOverviewEntity(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      invitedUsers: invitedUsers,
      inactiveUsers: inactiveUsers,
      usersByRole: usersByRole,
      usersByType: usersByType,
      usersJoinedLast7Days: usersJoinedLast7Days,
      usersJoinedLast30Days: usersJoinedLast30Days,
      lastUserJoinedAt: lastUserJoinedAt,
    );
  }
}

/// Main dashboard model
class DashboardModel {
  final ProjectOverviewModel projectOverview;
  final DeviceHealthSummaryModel deviceHealthSummary;
  final IncidentSnapshotModel incidentSnapshot;
  final RegionalInsightsModel regionalInsights;
  final UsersOverviewModel usersOverview;
  final DateTime lastUpdated;

  const DashboardModel({
    required this.projectOverview,
    required this.deviceHealthSummary,
    required this.incidentSnapshot,
    required this.regionalInsights,
    required this.usersOverview,
    required this.lastUpdated,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      projectOverview: ProjectOverviewModel.fromJson(
        json['project_overview'] as Map<String, dynamic>,
      ),
      deviceHealthSummary: DeviceHealthSummaryModel.fromJson(
        json['device_health_summary'] as Map<String, dynamic>,
      ),
      incidentSnapshot: IncidentSnapshotModel.fromJson(
        json['incident_snapshot'] as Map<String, dynamic>,
      ),
      regionalInsights: RegionalInsightsModel.fromJson(
        json['regional_insights'] as Map<String, dynamic>,
      ),
      usersOverview: UsersOverviewModel.fromJson(
        json['users_overview'] as Map<String, dynamic>,
      ),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_overview': projectOverview.toJson(),
      'device_health_summary': deviceHealthSummary.toJson(),
      'incident_snapshot': incidentSnapshot.toJson(),
      'regional_insights': regionalInsights.toJson(),
      'users_overview': usersOverview.toJson(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  DashboardEntity toEntity() {
    return DashboardEntity(
      projectOverview: projectOverview.toEntity(),
      deviceHealthSummary: deviceHealthSummary.toEntity(),
      incidentSnapshot: incidentSnapshot.toEntity(),
      regionalInsights: regionalInsights.toEntity(),
      usersOverview: usersOverview.toEntity(),
      lastUpdated: lastUpdated,
    );
  }
}
