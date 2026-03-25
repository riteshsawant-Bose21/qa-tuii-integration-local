import 'package:fusion_web/features/organizations/domain/entities/organization_entity.dart';

// Organization Model - Data layer representation
class OrganizationModel extends OrganizationEntity {
  const OrganizationModel({
    required super.id,
    required super.name,
    required super.type,
    required super.region,
    required super.status,
    required super.userCount,
    required super.ongoingProjectsCount,
    required super.completedProjectsCount,
    required super.createdAt,
    super.updatedAt,
    super.description,
    super.address,
    super.phone,
    super.email,
    super.website,
    super.contactPersonName,
    super.contactPersonEmail,
    super.contactPersonPhone,
    super.userIds = const [],
    super.projectIds = const [],
    super.isActive = true,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse DateTime from various formats
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        // Handle the specific "0001-01-01T00:00:00Z" case as null (invalid date)
        if (value.startsWith('0001-01-01')) return null;
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Failed to parse DateTime: $value');
          return null;
        }
      }
      return null;
    }

    // Helper function to safely get string value
    String getString(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Helper function to safely get int value
    int getInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return defaultValue;
        }
      }
      return defaultValue;
    }

    // Helper function to safely get list of strings
    List<String> getStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return OrganizationModel(
      id: getString(json['id'], ''),
      name: getString(json['name'], ''),
      type: OrganizationType.fromString(getString(json['type'], 'endUser')),
      region: OrganizationRegion.fromString(
        getString(json['region'], 'northAmerica'),
      ),
      status: OrganizationStatus.fromString(
        getString(json['status'], 'active'),
      ),
      userCount: getInt(
        json['userCount'] ?? json['users_count'] ?? json['totalUsers'],
        0,
      ),
      ongoingProjectsCount: getInt(
        json['ongoingProjectsCount'] ??
            json['ongoing_projects_count'] ??
            json['activeProjects'],
        0,
      ),
      completedProjectsCount: getInt(
        json['completedProjectsCount'] ??
            json['completed_projects_count'] ??
            json['completedProjects'],
        0,
      ),
      createdAt:
          parseDateTime(json['createdAt'] ?? json['created_at']) ??
          DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt'] ?? json['updated_at']),
      description: json['description'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      contactPersonName:
          json['contactPersonName'] ?? json['contact_person_name'],
      contactPersonEmail:
          json['contactPersonEmail'] ?? json['contact_person_email'],
      contactPersonPhone:
          json['contactPersonPhone'] ?? json['contact_person_phone'],
      userIds: getStringList(json['userIds'] ?? json['user_ids']),
      projectIds: getStringList(json['projectIds'] ?? json['project_ids']),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'region': region.name,
      'status': status.name,
      'userCount': userCount,
      'ongoingProjectsCount': ongoingProjectsCount,
      'completedProjectsCount': completedProjectsCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'contactPersonName': contactPersonName,
      'contactPersonEmail': contactPersonEmail,
      'contactPersonPhone': contactPersonPhone,
      'userIds': userIds,
      'projectIds': projectIds,
      'isActive': isActive,
    };
  }

  @override
  OrganizationModel copyWith({
    String? id,
    String? name,
    OrganizationType? type,
    OrganizationRegion? region,
    OrganizationStatus? status,
    int? userCount,
    int? ongoingProjectsCount,
    int? completedProjectsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? contactPersonName,
    String? contactPersonEmail,
    String? contactPersonPhone,
    List<String>? userIds,
    List<String>? projectIds,
    bool? isActive,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      region: region ?? this.region,
      status: status ?? this.status,
      userCount: userCount ?? this.userCount,
      ongoingProjectsCount: ongoingProjectsCount ?? this.ongoingProjectsCount,
      completedProjectsCount:
          completedProjectsCount ?? this.completedProjectsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPersonEmail: contactPersonEmail ?? this.contactPersonEmail,
      contactPersonPhone: contactPersonPhone ?? this.contactPersonPhone,
      userIds: userIds ?? this.userIds,
      projectIds: projectIds ?? this.projectIds,
      isActive: isActive ?? this.isActive,
    );
  }

  // Mock data for development/testing
  static List<OrganizationModel> mockOrganizations() {
    final now = DateTime.now();
    return [
      OrganizationModel(
        id: 'org-1',
        name: 'ProAudio Distribution NA',
        type: OrganizationType.distributor,
        region: OrganizationRegion.northAmerica,
        status: OrganizationStatus.active,
        userCount: 2,
        ongoingProjectsCount: 1,
        completedProjectsCount: 0,
        createdAt: now.subtract(const Duration(days: 365)),
        description: 'Leading audio equipment distributor in North America',
        address: '123 Audio Street, New York, NY 10001',
        phone: '+1-555-123-4567',
        email: 'info@proaudio.com',
        website: 'https://www.proaudio.com',
        contactPersonName: 'Mike Chen',
        contactPersonEmail: 'mike.chen@proaudio.com',
        contactPersonPhone: '+1-555-123-4567',
        userIds: ['user-1', 'user-2'],
        projectIds: ['project-1'],
      ),
      OrganizationModel(
        id: 'org-2',
        name: 'European Audio Systems',
        type: OrganizationType.distributor,
        region: OrganizationRegion.europe,
        status: OrganizationStatus.active,
        userCount: 1,
        ongoingProjectsCount: 0,
        completedProjectsCount: 2,
        createdAt: now.subtract(const Duration(days: 300)),
        description: 'Premier audio solutions for European markets',
        address: '456 Sound Avenue, London, UK SW1A 1AA',
        phone: '+44-20-7946-0958',
        email: 'info@euroaudio.com',
        website: 'https://www.euroaudio.com',
        contactPersonName: 'Emma Wilson',
        contactPersonEmail: 'emma.wilson@euroaudio.com',
        contactPersonPhone: '+44-20-7946-0958',
        userIds: ['user-3'],
        projectIds: ['project-2', 'project-3'],
      ),
      OrganizationModel(
        id: 'org-3',
        name: 'SoundTech Solutions',
        type: OrganizationType.reseller,
        region: OrganizationRegion.northAmerica,
        status: OrganizationStatus.active,
        userCount: 2,
        ongoingProjectsCount: 3,
        completedProjectsCount: 5,
        createdAt: now.subtract(const Duration(days: 200)),
        description: 'Specialized audio reseller for commercial installations',
        address: '789 Tech Boulevard, San Francisco, CA 94105',
        phone: '+1-555-987-6543',
        email: 'contact@soundtech.com',
        website: 'https://www.soundtech.com',
        contactPersonName: 'David Rodriguez',
        contactPersonEmail: 'david.rodriguez@soundtech.com',
        contactPersonPhone: '+1-555-987-6543',
        userIds: ['user-4', 'user-5'],
        projectIds: [
          'project-4',
          'project-5',
          'project-6',
          'project-7',
          'project-8',
        ],
      ),
      OrganizationModel(
        id: 'org-4',
        name: 'Skyline Hotels',
        type: OrganizationType.endUser,
        region: OrganizationRegion.northAmerica,
        status: OrganizationStatus.active,
        userCount: 1,
        ongoingProjectsCount: 1,
        completedProjectsCount: 3,
        createdAt: now.subtract(const Duration(days: 180)),
        description: 'Luxury hotel chain with premium audio requirements',
        address: '101 Luxury Lane, Miami, FL 33101',
        phone: '+1-555-555-0123',
        email: 'tech@skylinehotels.com',
        website: 'https://www.skylinehotels.com',
        contactPersonName: 'Sarah Johnson',
        contactPersonEmail: 'sarah.johnson@skylinehotels.com',
        contactPersonPhone: '+1-555-555-0123',
        userIds: ['user-6'],
        projectIds: ['project-9', 'project-10', 'project-11', 'project-12'],
      ),
      OrganizationModel(
        id: 'org-5',
        name: 'Metro University',
        type: OrganizationType.endUser,
        region: OrganizationRegion.northAmerica,
        status: OrganizationStatus.active,
        userCount: 1,
        ongoingProjectsCount: 2,
        completedProjectsCount: 1,
        createdAt: now.subtract(const Duration(days: 150)),
        description: 'Educational institution with advanced AV needs',
        address: '555 Education Drive, Boston, MA 02101',
        phone: '+1-555-EDU-TECH',
        email: 'av@metrouniversity.edu',
        website: 'https://www.metrouniversity.edu',
        contactPersonName: 'Dr. Michael Brown',
        contactPersonEmail: 'michael.brown@metrouniversity.edu',
        contactPersonPhone: '+1-555-EDU-TECH',
        userIds: ['user-7'],
        projectIds: ['project-13', 'project-14', 'project-15'],
      ),
      OrganizationModel(
        id: 'org-6',
        name: 'Global Retail Chain',
        type: OrganizationType.endUser,
        region: OrganizationRegion.europe,
        status: OrganizationStatus.active,
        userCount: 1,
        ongoingProjectsCount: 0,
        completedProjectsCount: 8,
        createdAt: now.subtract(const Duration(days: 120)),
        description: 'International retail company with stores worldwide',
        address: '777 Commerce Street, Paris, France 75001',
        phone: '+33-1-42-97-48-14',
        email: 'facilities@globalretail.com',
        website: 'https://www.globalretail.com',
        contactPersonName: 'Marie Dubois',
        contactPersonEmail: 'marie.dubois@globalretail.com',
        contactPersonPhone: '+33-1-42-97-48-14',
        userIds: ['user-8'],
        projectIds: [
          'project-16',
          'project-17',
          'project-18',
          'project-19',
          'project-20',
          'project-21',
          'project-22',
          'project-23',
        ],
      ),
    ];
  }
}
