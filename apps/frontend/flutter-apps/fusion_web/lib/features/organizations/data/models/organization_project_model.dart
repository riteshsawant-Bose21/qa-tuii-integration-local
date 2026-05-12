import 'package:fusion_web/features/organizations/domain/entities/organization_project_entity.dart';

// Organization Project Model - Data layer representation
class OrganizationProjectModel extends OrganizationProjectEntity {
  const OrganizationProjectModel({
    required super.id,
    required super.name,
    required super.status,
    required super.type,
    required super.region,
    required super.lastUpdated,
    required super.createdAt,
    required super.organizationId,
    super.description,
    super.budgetAmount,
    super.projectManagerId,
    super.assignedUserIds = const [],
  });

  factory OrganizationProjectModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse DateTime
    DateTime parseDateTime(dynamic value, DateTime defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return defaultValue;
        }
      }
      return defaultValue;
    }

    // Helper function to safely get string value
    String getString(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Helper function to safely get list of strings
    List<String> getStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    final now = DateTime.now();

    return OrganizationProjectModel(
      id: getString(json['id'], ''),
      name: getString(json['name'], ''),
      status: ProjectStatus.fromString(getString(json['status'], 'active')),
      type: ProjectType.fromString(getString(json['type'], 'opportunity')),
      region: getString(json['region'], 'North America'),
      lastUpdated: parseDateTime(
        json['lastUpdated'] ?? json['last_updated'],
        now,
      ),
      createdAt: parseDateTime(json['createdAt'] ?? json['created_at'], now),
      organizationId: getString(
        json['organizationId'] ?? json['organization_id'],
        '',
      ),
      description: json['description'],
      budgetAmount:
          json['budgetAmount']?.toDouble() ?? json['budget_amount']?.toDouble(),
      projectManagerId: json['projectManagerId'] ?? json['project_manager_id'],
      assignedUserIds: getStringList(
        json['assignedUserIds'] ?? json['assigned_user_ids'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
      'type': type.name,
      'region': region,
      'lastUpdated': lastUpdated.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'organizationId': organizationId,
      'description': description,
      'budgetAmount': budgetAmount,
      'projectManagerId': projectManagerId,
      'assignedUserIds': assignedUserIds,
    };
  }

  @override
  OrganizationProjectModel copyWith({
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
    return OrganizationProjectModel(
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

  // Mock data for projects
  static List<OrganizationProjectModel> mockProjectsForOrganization(
    String organizationId,
  ) {
    final now = DateTime.now();

    switch (organizationId) {
      case 'org-1': // ProAudio Distribution NA
        return [
          OrganizationProjectModel(
            id: 'project-1',
            name: 'Government Building Retrofit',
            status: ProjectStatus.active,
            type: ProjectType.opportunity,
            region: 'North America',
            lastUpdated: now.subtract(const Duration(days: 5)),
            createdAt: now.subtract(const Duration(days: 30)),
            organizationId: organizationId,
            description: 'Audio system retrofit for government building',
            budgetAmount: 150000.0,
            projectManagerId: 'user-1',
            assignedUserIds: ['user-1', 'user-2'],
          ),
        ];
      case 'org-2': // European Audio Systems
        return [
          OrganizationProjectModel(
            id: 'project-2',
            name: 'Conference Center Installation',
            status: ProjectStatus.completed,
            type: ProjectType.installation,
            region: 'Europe',
            lastUpdated: now.subtract(const Duration(days: 15)),
            createdAt: now.subtract(const Duration(days: 90)),
            organizationId: organizationId,
            description: 'Complete audio system for large conference center',
            budgetAmount: 200000.0,
            projectManagerId: 'user-3',
            assignedUserIds: ['user-3'],
          ),
          OrganizationProjectModel(
            id: 'project-3',
            name: 'Theater Sound Upgrade',
            status: ProjectStatus.completed,
            type: ProjectType.upgrade,
            region: 'Europe',
            lastUpdated: now.subtract(const Duration(days: 45)),
            createdAt: now.subtract(const Duration(days: 120)),
            organizationId: organizationId,
            description: 'Upgrade theater sound system',
            budgetAmount: 75000.0,
            projectManagerId: 'user-3',
            assignedUserIds: ['user-3'],
          ),
        ];
      case 'org-3': // SoundTech Solutions
        return [
          OrganizationProjectModel(
            id: 'project-4',
            name: 'Corporate Office Audio',
            status: ProjectStatus.active,
            type: ProjectType.installation,
            region: 'North America',
            lastUpdated: now.subtract(const Duration(days: 2)),
            createdAt: now.subtract(const Duration(days: 20)),
            organizationId: organizationId,
            description: 'Office building audio system installation',
            budgetAmount: 50000.0,
            projectManagerId: 'user-4',
            assignedUserIds: ['user-4', 'user-5'],
          ),
          OrganizationProjectModel(
            id: 'project-5',
            name: 'Restaurant Chain Rollout',
            status: ProjectStatus.active,
            type: ProjectType.opportunity,
            region: 'North America',
            lastUpdated: now.subtract(const Duration(days: 1)),
            createdAt: now.subtract(const Duration(days: 15)),
            organizationId: organizationId,
            description: 'Audio systems for restaurant chain',
            budgetAmount: 300000.0,
            projectManagerId: 'user-4',
            assignedUserIds: ['user-4'],
          ),
        ];
      case 'org-4': // Skyline Hotels
        return [
          OrganizationProjectModel(
            id: 'project-9',
            name: 'Hotel Lobby Renovation',
            status: ProjectStatus.active,
            type: ProjectType.upgrade,
            region: 'North America',
            lastUpdated: now.subtract(const Duration(days: 3)),
            createdAt: now.subtract(const Duration(days: 25)),
            organizationId: organizationId,
            description: 'Complete lobby audio system upgrade',
            budgetAmount: 80000.0,
            projectManagerId: 'user-6',
            assignedUserIds: ['user-6'],
          ),
        ];
      case 'org-5': // Metro University
        return [
          OrganizationProjectModel(
            id: 'project-13',
            name: 'Lecture Hall Audio Upgrade',
            status: ProjectStatus.active,
            type: ProjectType.upgrade,
            region: 'North America',
            lastUpdated: now.subtract(const Duration(days: 7)),
            createdAt: now.subtract(const Duration(days: 40)),
            organizationId: organizationId,
            description: 'Modernize lecture hall audio systems',
            budgetAmount: 120000.0,
            projectManagerId: 'user-7',
            assignedUserIds: ['user-7'],
          ),
          OrganizationProjectModel(
            id: 'project-14',
            name: 'Campus Event Center',
            status: ProjectStatus.active,
            type: ProjectType.installation,
            region: 'North America',
            lastUpdated: now.subtract(const Duration(days: 4)),
            createdAt: now.subtract(const Duration(days: 35)),
            organizationId: organizationId,
            description: 'New event center audio installation',
            budgetAmount: 250000.0,
            projectManagerId: 'user-7',
            assignedUserIds: ['user-7'],
          ),
        ];
      default:
        return [];
    }
  }

  OrganizationProjectEntity toEntity() {
    return OrganizationProjectEntity(
      id: id,
      name: name,
      status: status,
      type: type,
      region: region,
      lastUpdated: lastUpdated,
      createdAt: createdAt,
      organizationId: organizationId,
      description: description,
      budgetAmount: budgetAmount,
      projectManagerId: projectManagerId,
      assignedUserIds: assignedUserIds,
    );
  }
}
