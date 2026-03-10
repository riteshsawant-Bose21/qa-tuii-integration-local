/// Project status enumeration
enum ProjectStatus {
  active,
  completed,
  archived;

  String get displayName {
    switch (this) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.archived:
        return 'Archived';
    }
  }

  static ProjectStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return ProjectStatus.active;
      case 'completed':
        return ProjectStatus.completed;
      case 'archived':
        return ProjectStatus.archived;
      default:
        return ProjectStatus.active;
    }
  }
}

/// Device health status enumeration
enum DeviceHealthStatus {
  healthy,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case DeviceHealthStatus.healthy:
        return 'Healthy';
      case DeviceHealthStatus.warning:
        return 'Warning';
      case DeviceHealthStatus.critical:
        return 'Critical';
    }
  }

  static DeviceHealthStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return DeviceHealthStatus.healthy;
      case 'warning':
        return DeviceHealthStatus.warning;
      case 'critical':
        return DeviceHealthStatus.critical;
      default:
        return DeviceHealthStatus.healthy;
    }
  }
}

/// Incident priority enumeration
enum IncidentPriority {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case IncidentPriority.low:
        return 'Low';
      case IncidentPriority.medium:
        return 'Medium';
      case IncidentPriority.high:
        return 'High';
      case IncidentPriority.critical:
        return 'Critical';
    }
  }

  static IncidentPriority fromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return IncidentPriority.low;
      case 'medium':
        return IncidentPriority.medium;
      case 'high':
        return IncidentPriority.high;
      case 'critical':
        return IncidentPriority.critical;
      default:
        return IncidentPriority.medium;
    }
  }
}

/// Project overview entity
class ProjectOverviewEntity {
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final int archivedProjects;
  final Map<String, int> projectsByRegion;
  final int recentActivityCount7Days;
  final int recentActivityCount30Days;

  const ProjectOverviewEntity({
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.archivedProjects,
    required this.projectsByRegion,
    required this.recentActivityCount7Days,
    required this.recentActivityCount30Days,
  });
}

/// Device health summary entity
class DeviceHealthSummaryEntity {
  final int healthyDevicesCount;
  final int warningDevicesCount;
  final int criticalDevicesCount;
  final Map<String, int> topDeviceModels;
  final int incidentsLast7Days;
  final int incidentsLast30Days;

  const DeviceHealthSummaryEntity({
    required this.healthyDevicesCount,
    required this.warningDevicesCount,
    required this.criticalDevicesCount,
    required this.topDeviceModels,
    required this.incidentsLast7Days,
    required this.incidentsLast30Days,
  });

  int get totalDevices =>
      healthyDevicesCount + warningDevicesCount + criticalDevicesCount;
}

/// Incident snapshot entity
class IncidentSnapshotEntity {
  final int totalOpenIncidents;
  final int criticalAlerts;
  final List<IncidentTrendPoint> incidentTrendData;
  final Map<String, int> topIncidentCategories;

  const IncidentSnapshotEntity({
    required this.totalOpenIncidents,
    required this.criticalAlerts,
    required this.incidentTrendData,
    required this.topIncidentCategories,
  });
}

/// Incident trend data point
class IncidentTrendPoint {
  final DateTime date;
  final int count;

  const IncidentTrendPoint({required this.date, required this.count});
}

/// Regional insights entity
class RegionalInsightsEntity {
  final Map<String, int> projectsByRegion;
  final Map<String, int> activePartnersByRegion;
  final Map<String, int> devicesByGeography;
  final Map<String, double> salesKPIs;

  const RegionalInsightsEntity({
    required this.projectsByRegion,
    required this.activePartnersByRegion,
    required this.devicesByGeography,
    required this.salesKPIs,
  });
}

/// Users overview entity
class UsersOverviewEntity {
  final int totalUsers;
  final int activeUsers;
  final int invitedUsers;
  final int inactiveUsers;
  final Map<String, int> usersByRole;
  final Map<String, int> usersByType;
  final int usersJoinedLast7Days;
  final int usersJoinedLast30Days;
  final DateTime? lastUserJoinedAt;

  const UsersOverviewEntity({
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
}

/// Main dashboard entity containing all metrics
class DashboardEntity {
  final ProjectOverviewEntity projectOverview;
  final DeviceHealthSummaryEntity deviceHealthSummary;
  final IncidentSnapshotEntity incidentSnapshot;
  final RegionalInsightsEntity regionalInsights;
  final UsersOverviewEntity usersOverview;
  final DateTime lastUpdated;

  const DashboardEntity({
    required this.projectOverview,
    required this.deviceHealthSummary,
    required this.incidentSnapshot,
    required this.regionalInsights,
    required this.usersOverview,
    required this.lastUpdated,
  });
}
