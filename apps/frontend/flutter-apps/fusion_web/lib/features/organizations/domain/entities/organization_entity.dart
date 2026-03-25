// Organization Type Enum
enum OrganizationType {
  distributor,
  reseller,
  endUser;

  String get displayName {
    switch (this) {
      case OrganizationType.distributor:
        return 'Distributor';
      case OrganizationType.reseller:
        return 'Reseller';
      case OrganizationType.endUser:
        return 'End User / System Owner';
    }
  }

  static OrganizationType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'distributor':
        return OrganizationType.distributor;
      case 'reseller':
        return OrganizationType.reseller;
      case 'enduser':
      case 'end_user':
      case 'system_owner':
        return OrganizationType.endUser;
      default:
        return OrganizationType.endUser;
    }
  }
}

// Organization Region Enum
enum OrganizationRegion {
  northAmerica,
  europe,
  asia,
  southAmerica,
  africa,
  oceania;

  String get displayName {
    switch (this) {
      case OrganizationRegion.northAmerica:
        return 'North America';
      case OrganizationRegion.europe:
        return 'Europe';
      case OrganizationRegion.asia:
        return 'Asia';
      case OrganizationRegion.southAmerica:
        return 'South America';
      case OrganizationRegion.africa:
        return 'Africa';
      case OrganizationRegion.oceania:
        return 'Oceania';
    }
  }

  static OrganizationRegion fromString(String region) {
    switch (region.toLowerCase()) {
      case 'north_america':
      case 'northamerica':
      case 'north america':
        return OrganizationRegion.northAmerica;
      case 'europe':
        return OrganizationRegion.europe;
      case 'asia':
        return OrganizationRegion.asia;
      case 'south_america':
      case 'southamerica':
      case 'south america':
        return OrganizationRegion.southAmerica;
      case 'africa':
        return OrganizationRegion.africa;
      case 'oceania':
        return OrganizationRegion.oceania;
      default:
        return OrganizationRegion.northAmerica;
    }
  }
}

// Organization Status Enum
enum OrganizationStatus {
  active,
  inactive,
  pending,
  suspended;

  String get displayName {
    switch (this) {
      case OrganizationStatus.active:
        return 'Active';
      case OrganizationStatus.inactive:
        return 'Inactive';
      case OrganizationStatus.pending:
        return 'Pending';
      case OrganizationStatus.suspended:
        return 'Suspended';
    }
  }

  static OrganizationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return OrganizationStatus.active;
      case 'inactive':
        return OrganizationStatus.inactive;
      case 'pending':
        return OrganizationStatus.pending;
      case 'suspended':
        return OrganizationStatus.suspended;
      default:
        return OrganizationStatus.active;
    }
  }
}

// Organization Entity - Domain layer representation
class OrganizationEntity {
  final String id;
  final String name;
  final OrganizationType type;
  final OrganizationRegion region;
  final OrganizationStatus status;
  final int userCount;
  final int ongoingProjectsCount;
  final int completedProjectsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? description;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? contactPersonName;
  final String? contactPersonEmail;
  final String? contactPersonPhone;
  final List<String> userIds;
  final List<String> projectIds;
  final bool isActive;

  const OrganizationEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.region,
    required this.status,
    required this.userCount,
    required this.ongoingProjectsCount,
    required this.completedProjectsCount,
    required this.createdAt,
    this.updatedAt,
    this.description,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.contactPersonName,
    this.contactPersonEmail,
    this.contactPersonPhone,
    this.userIds = const [],
    this.projectIds = const [],
    this.isActive = true,
  });

  // Helper method to get total projects count
  int get totalProjectsCount => ongoingProjectsCount + completedProjectsCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OrganizationEntity{id: $id, name: $name, type: $type, region: $region, userCount: $userCount}';
  }

  // CopyWith method for creating modified copies
  OrganizationEntity copyWith({
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
    return OrganizationEntity(
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
}
