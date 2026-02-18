class ProjectEntity {
  final String id;
  final String title;
  final String description;
  final String clientName;
  final String region;
  final String status;

  final int healthyDevices;
  final int warningDevices;
  final int criticalDevices;
  final int incidents;

  final DateTime lastUpdated;

  const ProjectEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.clientName,
    required this.region,
    required this.status,
    required this.healthyDevices,
    required this.warningDevices,
    required this.criticalDevices,
    required this.incidents,
    required this.lastUpdated,
  });

  ProjectEntity copyWith({
    String? title,
    String? description,
    String? clientName,
    String? region,
    String? status,
    int? healthyDevices,
    int? warningDevices,
    int? criticalDevices,
    int? incidents,
    DateTime? lastUpdated,
  }) {
    return ProjectEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      clientName: clientName ?? this.clientName,
      region: region ?? this.region,
      status: status ?? this.status,
      healthyDevices: healthyDevices ?? this.healthyDevices,
      warningDevices: warningDevices ?? this.warningDevices,
      criticalDevices: criticalDevices ?? this.criticalDevices,
      incidents: incidents ?? this.incidents,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
