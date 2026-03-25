// Project Status Enum
enum ProjectStatus {
  active,
  completed,
  paused,
  cancelled;

  String get displayName {
    switch (this) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.paused:
        return 'Paused';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ProjectStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return ProjectStatus.active;
      case 'completed':
        return ProjectStatus.completed;
      case 'paused':
        return ProjectStatus.paused;
      case 'cancelled':
        return ProjectStatus.cancelled;
      default:
        return ProjectStatus.active;
    }
  }
}

// Project Type Enum
enum ProjectType {
  opportunity,
  installation,
  maintenance,
  upgrade;

  String get displayName {
    switch (this) {
      case ProjectType.opportunity:
        return 'Opportunity';
      case ProjectType.installation:
        return 'Installation';
      case ProjectType.maintenance:
        return 'Maintenance';
      case ProjectType.upgrade:
        return 'Upgrade';
    }
  }

  static ProjectType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'opportunity':
        return ProjectType.opportunity;
      case 'installation':
        return ProjectType.installation;
      case 'maintenance':
        return ProjectType.maintenance;
      case 'upgrade':
        return ProjectType.upgrade;
      default:
        return ProjectType.opportunity;
    }
  }
}

// Organization Project Entity - Simplified project info for organization contexts
class OrganizationProjectEntity {
  final String id;
  final String name;
  final ProjectStatus status;
  final ProjectType type;
  final String region;
  final DateTime lastUpdated;
  final DateTime createdAt;
  final String organizationId;
  final String? description;
  final double? budgetAmount;
  final String? projectManagerId;
  final List<String> assignedUserIds;

  const OrganizationProjectEntity({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
    required this.region,
    required this.lastUpdated,
    required this.createdAt,
    required this.organizationId,
    this.description,
    this.budgetAmount,
    this.projectManagerId,
    this.assignedUserIds = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationProjectEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OrganizationProjectEntity{id: $id, name: $name, status: $status, type: $type, organizationId: $organizationId}';
  }

  // CopyWith method for creating modified copies
  OrganizationProjectEntity copyWith({
    String? id,
    String? name,
    ProjectStatus? status,
    ProjectType? type,
    String? region,
    DateTime? lastUpdated,
    DateTime? createdAt,
    String? organizationId,
    String? description,
    double? budgetAmount,
    String? projectManagerId,
    List<String>? assignedUserIds,
  }) {
    return OrganizationProjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      type: type ?? this.type,
      region: region ?? this.region,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      organizationId: organizationId ?? this.organizationId,
      description: description ?? this.description,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      projectManagerId: projectManagerId ?? this.projectManagerId,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
    );
  }
}
