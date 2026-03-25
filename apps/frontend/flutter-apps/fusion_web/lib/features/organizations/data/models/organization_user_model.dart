import 'package:fusion_web/features/organizations/domain/entities/organization_user_entity.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';

// Organization User Model - Data layer representation
class OrganizationUserModel extends OrganizationUserEntity {
  const OrganizationUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.roles,
    required super.status,
    required super.userType,
    required super.createdAt,
    required super.organizationId,
    super.lastLoginAt,
    super.inviteDate,
    super.avatar,
    super.phone,
    super.isActive = true,
  });

  factory OrganizationUserModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse DateTime
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        if (value.startsWith('0001-01-01')) return null;
        try {
          return DateTime.parse(value);
        } catch (e) {
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

    // Helper function to extract role names from role object
    List<String> getRolesList(dynamic roleValue) {
      if (roleValue == null) return ['User'];
      if (roleValue is List) {
        return roleValue.map((e) => e.toString()).toList();
      }
      if (roleValue is Map && roleValue['name'] != null) {
        return [roleValue['name'].toString()];
      }
      if (roleValue is String) {
        return [roleValue];
      }
      return ['User'];
    }

    return OrganizationUserModel(
      id: getString(json['id'], ''),
      name: getString(
        json['name'] ?? json['fullName'] ?? json['username'],
        'Unknown User',
      ),
      email: getString(json['email'], ''),
      roles: getRolesList(json['roles'] ?? json['role']),
      status: UserStatus.fromString(getString(json['status'], 'active')),
      userType: UserType.fromString(
        getString(json['userType'] ?? json['type'], 'viewer'),
      ),
      createdAt:
          parseDateTime(json['createdAt'] ?? json['created_at']) ??
          DateTime.now(),
      organizationId: getString(
        json['organizationId'] ?? json['organization_id'],
        '',
      ),
      lastLoginAt: parseDateTime(json['lastLoginAt'] ?? json['last_login_at']),
      inviteDate: parseDateTime(json['inviteDate'] ?? json['invite_date']),
      avatar: json['avatar'] ?? json['profilePicture'],
      phone: json['phone'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'roles': roles,
      'status': status.name,
      'userType': userType.name,
      'createdAt': createdAt.toIso8601String(),
      'organizationId': organizationId,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'inviteDate': inviteDate?.toIso8601String(),
      'avatar': avatar,
      'phone': phone,
      'isActive': isActive,
    };
  }

  // Factory method to create from UserEntity
  factory OrganizationUserModel.fromUserEntity(
    UserEntity user,
    String organizationId,
  ) {
    return OrganizationUserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      roles: user.roles,
      status: user.status,
      userType: user.userType,
      createdAt: user.createdAt,
      organizationId: organizationId,
      lastLoginAt: user.lastLoginAt,
      inviteDate: user.inviteDate,
      avatar: user.avatar,
      phone: user.phone,
      isActive: user.isActive,
    );
  }

  @override
  OrganizationUserModel copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? roles,
    UserStatus? status,
    UserType? userType,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? inviteDate,
    String? avatar,
    String? organizationId,
    String? phone,
    bool? isActive,
  }) {
    return OrganizationUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      status: status ?? this.status,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      organizationId: organizationId ?? this.organizationId,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      inviteDate: inviteDate ?? this.inviteDate,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }

  // Mock data for organization users
  static List<OrganizationUserModel> mockUsersForOrganization(
    String organizationId,
  ) {
    final now = DateTime.now();

    switch (organizationId) {
      case 'org-1': // ProAudio Distribution NA
        return [
          OrganizationUserModel(
            id: 'user-1',
            name: 'Mike Chen',
            email: 'mike.chen@proaudio.com',
            roles: ['Partner Admin'],
            status: UserStatus.active,
            userType: UserType.admin,
            createdAt: now.subtract(const Duration(days: 365)),
            organizationId: organizationId,
            lastLoginAt: now.subtract(const Duration(hours: 2)),
            phone: '+1-555-123-4567',
          ),
          OrganizationUserModel(
            id: 'user-2',
            name: 'Lisa Martinez',
            email: 'lisa.martinez@proaudio.com',
            roles: ['Partner User'],
            status: UserStatus.active,
            userType: UserType.contributor,
            createdAt: now.subtract(const Duration(days: 350)),
            organizationId: organizationId,
            lastLoginAt: now.subtract(const Duration(days: 1)),
            inviteDate: now.subtract(const Duration(days: 350)),
            phone: '+1-555-123-4568',
          ),
        ];
      case 'org-2': // European Audio Systems
        return [
          OrganizationUserModel(
            id: 'user-3',
            name: 'Emma Wilson',
            email: 'emma.wilson@euroaudio.com',
            roles: ['Partner Admin'],
            status: UserStatus.active,
            userType: UserType.admin,
            createdAt: now.subtract(const Duration(days: 300)),
            organizationId: organizationId,
            lastLoginAt: now.subtract(const Duration(days: 3)),
            phone: '+44-20-7946-0958',
          ),
        ];
      case 'org-3': // SoundTech Solutions
        return [
          OrganizationUserModel(
            id: 'user-4',
            name: 'David Rodriguez',
            email: 'david.rodriguez@soundtech.com',
            roles: ['Reseller Admin'],
            status: UserStatus.active,
            userType: UserType.admin,
            createdAt: now.subtract(const Duration(days: 200)),
            organizationId: organizationId,
            lastLoginAt: now.subtract(const Duration(hours: 6)),
            phone: '+1-555-987-6543',
          ),
          OrganizationUserModel(
            id: 'user-5',
            name: 'Jennifer Kim',
            email: 'jennifer.kim@soundtech.com',
            roles: ['Reseller User'],
            status: UserStatus.active,
            userType: UserType.contributor,
            createdAt: now.subtract(const Duration(days: 180)),
            organizationId: organizationId,
            lastLoginAt: now.subtract(const Duration(hours: 12)),
            phone: '+1-555-987-6544',
          ),
        ];
      case 'org-4': // Skyline Hotels
        return [
          OrganizationUserModel(
            id: 'user-6',
            name: 'Sarah Johnson',
            email: 'sarah.johnson@skylinehotels.com',
            roles: ['System Owner'],
            status: UserStatus.active,
            userType: UserType.admin,
            createdAt: now.subtract(const Duration(days: 180)),
            organizationId: organizationId,
            lastLoginAt: now.subtract(const Duration(hours: 8)),
            phone: '+1-555-555-0123',
          ),
        ];
      case 'org-5': // Metro University
        return [
          OrganizationUserModel(
            id: 'user-7',
            name: 'Dr. Michael Brown',
            email: 'michael.brown@metrouniversity.edu',
            roles: ['System Owner'],
            status: UserStatus.active,
            userType: UserType.admin,
            createdAt: now.subtract(const Duration(days: 150)),
            organizationId: organizationId,
            lastLoginAt: now.subtract(const Duration(hours: 4)),
            phone: '+1-555-EDU-TECH',
          ),
        ];
      case 'org-6': // Global Retail Chain
        return [
          OrganizationUserModel(
            id: 'user-8',
            name: 'Marie Dubois',
            email: 'marie.dubois@globalretail.com',
            roles: ['System Owner'],
            status: UserStatus.active,
            userType: UserType.admin,
            createdAt: now.subtract(const Duration(days: 120)),
            organizationId: organizationId,
            lastLoginAt: now.subtract(const Duration(days: 2)),
            phone: '+33-1-42-97-48-14',
          ),
        ];
      default:
        return [];
    }
  }

  OrganizationUserEntity toEntity() {
    return OrganizationUserEntity(
      id: id,
      name: name,
      email: email,
      roles: roles,
      status: status,
      userType: userType,
      createdAt: createdAt,
      organizationId: organizationId,
      lastLoginAt: lastLoginAt,
      inviteDate: inviteDate,
      avatar: avatar,
      phone: phone,
      isActive: isActive,
    );
  }
}
