// Project Entity - Represents a work project
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

  // Equality check - ensures Flutter knows if two project objects are the same
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
