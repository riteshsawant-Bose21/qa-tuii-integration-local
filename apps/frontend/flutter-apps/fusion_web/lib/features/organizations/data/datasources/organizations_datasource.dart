import 'package:fusion_web/core/services/api_service.dart';
import 'package:fusion_web/features/organizations/data/models/organization_model.dart';
import 'package:fusion_web/features/organizations/data/models/organization_user_model.dart';
import 'package:fusion_web/features/organizations/data/models/organization_project_model.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_entity.dart';
import 'package:fusion_web/features/organizations/domain/repositories/organizations_repository.dart';

abstract class OrganizationsDataSource {
  Future<List<OrganizationModel>> getOrganizations();
  Future<OrganizationModel> getOrganizationById(String id);
  Future<OrganizationModel> createOrganization(OrganizationEntity organization);
  Future<OrganizationModel> updateOrganization(OrganizationEntity organization);
  Future<bool> deleteOrganization(String id);
  Future<List<OrganizationModel>> searchOrganizations(String query);
  Future<List<OrganizationModel>> filterOrganizations(
    OrganizationFilterParams params,
  );
  Future<OrganizationMetrics> getOrganizationMetrics();
  Future<List<OrganizationUserModel>> getOrganizationUsers(
    String organizationId,
  );
  Future<List<OrganizationProjectModel>> getOrganizationProjects(
    String organizationId,
  );
  Future<OrganizationModel> activateOrganization(String id);
  Future<OrganizationModel> deactivateOrganization(String id);
}

class OrganizationsRemoteDataSource implements OrganizationsDataSource {
  final ApiService apiService;

  // Static cache for organization details with users and projects
  static final Map<String, List<OrganizationUserModel>> _cachedUsers = {};
  static final Map<String, List<OrganizationProjectModel>> _cachedProjects = {};

  OrganizationsRemoteDataSource({required this.apiService});

  // Method to clear cached data for a specific organization or all organizations
  static void clearCache([String? organizationId]) {
    if (organizationId != null) {
      _cachedUsers.remove(organizationId);
      _cachedProjects.remove(organizationId);
      print('🗑️ Cleared cache for organization: $organizationId');
    } else {
      _cachedUsers.clear();
      _cachedProjects.clear();
      print('🗑️ Cleared all organization caches');
    }
  }

  @override
  Future<List<OrganizationModel>> getOrganizations() async {
    try {
      final response = await apiService.get('/organizations');

      // Handle the actual API response structure: {organizations: [...], statistics: {...}}
      if (response['organizations'] != null) {
        final List<dynamic> organizationsJson = response['organizations'];
        return organizationsJson
            .map((json) => OrganizationModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Organizations API Error: $e');
      throw Exception('Failed to fetch organizations: ${e.toString()}');
    }
  }

  @override
  Future<OrganizationModel> getOrganizationById(String id) async {
    try {
      print('📋 Fetching organization data for ID: $id');
      final response = await apiService.get('/organizations/$id');

      // Handle new API response structure
      if (response['organization'] != null) {
        final organizationData = response['organization'];

        // Cache users if present
        if (response['users'] != null) {
          final List<dynamic> usersJson = response['users'];
          _cachedUsers[id] = usersJson
              .map((json) => OrganizationUserModel.fromJson(json))
              .toList();
          print('💾 Cached ${_cachedUsers[id]!.length} users for org: $id');
        }

        // Cache projects if present
        if (response['projects'] != null) {
          final List<dynamic> projectsJson = response['projects'];
          _cachedProjects[id] = projectsJson
              .map((json) => OrganizationProjectModel.fromJson(json))
              .toList();
          print(
            '💾 Cached ${_cachedProjects[id]!.length} projects for org: $id',
          );
        }

        return OrganizationModel.fromJson(organizationData);
      }

      // Fallback to old structure for backward compatibility
      if (response['success'] == true && response['data'] != null) {
        return OrganizationModel.fromJson(response['data']);
      }

      throw Exception('Organization not found');
    } catch (e) {
      throw Exception('Failed to fetch organization: ${e.toString()}');
    }
  }

  @override
  Future<OrganizationModel> createOrganization(
    OrganizationEntity organization,
  ) async {
    try {
      final organizationModel = OrganizationModel.fromEntity(organization);
      final response = await apiService.post(
        'organizations',
        organizationModel.toJson(),
      );
      if (response['success'] == true && response['data'] != null) {
        return OrganizationModel.fromJson(response['data']);
      }
      throw Exception('Failed to create organization');
    } catch (e) {
      throw Exception('Failed to create organization: ${e.toString()}');
    }
  }

  @override
  Future<OrganizationModel> updateOrganization(
    OrganizationEntity organization,
  ) async {
    try {
      final organizationModel = OrganizationModel.fromEntity(organization);
      final response = await apiService.put(
        'organizations/${organization.id}',
        organizationModel.toJson(),
      );
      if (response['success'] == true && response['data'] != null) {
        return OrganizationModel.fromJson(response['data']);
      }
      throw Exception('Failed to update organization');
    } catch (e) {
      throw Exception('Failed to update organization: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteOrganization(String id) async {
    try {
      await apiService.delete('organizations/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete organization: ${e.toString()}');
    }
  }

  @override
  Future<List<OrganizationModel>> searchOrganizations(String query) async {
    try {
      final response = await apiService.get(
        'organizations/search?q=${Uri.encodeComponent(query)}',
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> organizationsJson = response['data'];
        return organizationsJson
            .map((json) => OrganizationModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search organizations: ${e.toString()}');
    }
  }

  @override
  Future<List<OrganizationModel>> filterOrganizations(
    OrganizationFilterParams params,
  ) async {
    try {
      final queryParams = <String, dynamic>{};
      if (params.type != null) queryParams['type'] = params.type!.name;
      if (params.region != null) queryParams['region'] = params.region!.name;
      if (params.status != null) queryParams['status'] = params.status!.name;
      if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
        queryParams['search'] = params.searchQuery;
      }

      final queryString = queryParams.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
          )
          .join('&');
      final response = await apiService.get(
        'organizations/filter?$queryString',
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> organizationsJson = response['data'];
        return organizationsJson
            .map((json) => OrganizationModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to filter organizations: ${e.toString()}');
    }
  }

  @override
  Future<OrganizationMetrics> getOrganizationMetrics() async {
    try {
      // Use the organizations endpoint since it includes statistics
      final response = await apiService.get('/organizations');

      if (response['statistics'] != null) {
        final stats = response['statistics'];
        final totalCount = response['total_count'] ?? 0;

        return OrganizationMetrics(
          totalDistributors: stats['total_distributors'] ?? 0,
          totalResellers: stats['total_resellers'] ?? 0,
          totalEndUsers: stats['total_end_users'] ?? 0,
          totalOrganizations: totalCount,
        );
      }

      return const OrganizationMetrics(
        totalDistributors: 0,
        totalResellers: 0,
        totalEndUsers: 0,
        totalOrganizations: 0,
      );
    } catch (e) {
      throw Exception('Failed to fetch organization metrics: ${e.toString()}');
    }
  }

  @override
  Future<List<OrganizationUserModel>> getOrganizationUsers(
    String organizationId,
  ) async {
    // Return cached users if available (from getOrganizationById call)
    if (_cachedUsers.containsKey(organizationId)) {
      print(
        '📦 Using cached users for org: $organizationId (${_cachedUsers[organizationId]!.length} users)',
      );
      return _cachedUsers[organizationId]!;
    }

    print('🌐 Fetching users from API for org: $organizationId');
    // Fallback: try separate API call
    try {
      final response = await apiService.get(
        '/organizations/$organizationId/users',
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> usersJson = response['data'];
        final users = usersJson
            .map((json) => OrganizationUserModel.fromJson(json))
            .toList();
        // Cache for future use
        _cachedUsers[organizationId] = users;
        print(
          '💾 Cached ${users.length} users from API for org: $organizationId',
        );
        return users;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch organization users: ${e.toString()}');
    }
  }

  @override
  Future<List<OrganizationProjectModel>> getOrganizationProjects(
    String organizationId,
  ) async {
    // Return cached projects if available (from getOrganizationById call)
    if (_cachedProjects.containsKey(organizationId)) {
      print(
        '📦 Using cached projects for org: $organizationId (${_cachedProjects[organizationId]!.length} projects)',
      );
      return _cachedProjects[organizationId]!;
    }

    print('🌐 Fetching projects from API for org: $organizationId');
    // Fallback: try separate API call
    try {
      final response = await apiService.get(
        '/organizations/$organizationId/projects',
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> projectsJson = response['data'];
        final projects = projectsJson
            .map((json) => OrganizationProjectModel.fromJson(json))
            .toList();
        // Cache for future use
        _cachedProjects[organizationId] = projects;
        print(
          '💾 Cached ${projects.length} projects from API for org: $organizationId',
        );
        return projects;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch organization projects: ${e.toString()}');
    }
  }

  @override
  Future<OrganizationModel> activateOrganization(String id) async {
    try {
      final response = await apiService.post('organizations/$id/activate', {});
      if (response['success'] == true && response['data'] != null) {
        return OrganizationModel.fromJson(response['data']);
      }
      throw Exception('Failed to activate organization');
    } catch (e) {
      throw Exception('Failed to activate organization: ${e.toString()}');
    }
  }

  @override
  Future<OrganizationModel> deactivateOrganization(String id) async {
    try {
      final response = await apiService.post(
        'organizations/$id/deactivate',
        {},
      );
      if (response['success'] == true && response['data'] != null) {
        return OrganizationModel.fromJson(response['data']);
      }
      throw Exception('Failed to deactivate organization');
    } catch (e) {
      throw Exception('Failed to deactivate organization: ${e.toString()}');
    }
  }
}

class OrganizationsLocalDataSource implements OrganizationsDataSource {
  List<OrganizationModel> _cachedOrganizations = [];
  OrganizationMetrics? _cachedMetrics;

  OrganizationsLocalDataSource();

  @override
  Future<List<OrganizationModel>> getOrganizations() async {
    return _cachedOrganizations;
  }

  @override
  Future<OrganizationModel> getOrganizationById(String id) async {
    try {
      return _cachedOrganizations.firstWhere((org) => org.id == id);
    } catch (e) {
      throw Exception('Organization not found in cache');
    }
  }

  @override
  Future<OrganizationModel> createOrganization(
    OrganizationEntity organization,
  ) async {
    // Local storage doesn't support creating - this is a fallback
    throw UnimplementedError(
      'Creating organizations not supported in local cache',
    );
  }

  @override
  Future<OrganizationModel> updateOrganization(
    OrganizationEntity organization,
  ) async {
    // Local storage doesn't support updating - this is a fallback
    throw UnimplementedError(
      'Updating organizations not supported in local cache',
    );
  }

  @override
  Future<bool> deleteOrganization(String id) async {
    // Local storage doesn't support deleting - this is a fallback
    throw UnimplementedError(
      'Deleting organizations not supported in local cache',
    );
  }

  @override
  Future<List<OrganizationModel>> searchOrganizations(String query) async {
    return _cachedOrganizations.where((org) {
      return org.name.toLowerCase().contains(query.toLowerCase()) ||
          (org.description?.toLowerCase().contains(query.toLowerCase()) ??
              false);
    }).toList();
  }

  @override
  Future<List<OrganizationModel>> filterOrganizations(
    OrganizationFilterParams params,
  ) async {
    return _cachedOrganizations.where((org) {
      bool matches = true;

      if (params.type != null) {
        matches = matches && org.type == params.type!;
      }

      if (params.region != null) {
        matches = matches && org.region == params.region!;
      }

      if (params.status != null) {
        matches = matches && org.status == params.status!;
      }

      if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
        matches =
            matches &&
            (org.name.toLowerCase().contains(
                  params.searchQuery!.toLowerCase(),
                ) ||
                (org.description?.toLowerCase().contains(
                      params.searchQuery!.toLowerCase(),
                    ) ??
                    false));
      }

      return matches;
    }).toList();
  }

  @override
  Future<OrganizationMetrics> getOrganizationMetrics() async {
    return _cachedMetrics ??
        const OrganizationMetrics(
          totalDistributors: 0,
          totalResellers: 0,
          totalEndUsers: 0,
          totalOrganizations: 0,
        );
  }

  @override
  Future<List<OrganizationUserModel>> getOrganizationUsers(
    String organizationId,
  ) async {
    // Local storage doesn't cache individual organization users
    return [];
  }

  @override
  Future<List<OrganizationProjectModel>> getOrganizationProjects(
    String organizationId,
  ) async {
    // Local storage doesn't cache individual organization projects
    return [];
  }

  @override
  Future<OrganizationModel> activateOrganization(String id) async {
    throw UnimplementedError(
      'Activating organizations not supported in local cache',
    );
  }

  @override
  Future<OrganizationModel> deactivateOrganization(String id) async {
    throw UnimplementedError(
      'Deactivating organizations not supported in local cache',
    );
  }

  // Cache management methods
  void cacheOrganizations(List<OrganizationModel> organizations) {
    _cachedOrganizations = organizations;
  }

  void cacheMetrics(OrganizationMetrics metrics) {
    _cachedMetrics = metrics;
  }

  void clearCache() {
    _cachedOrganizations.clear();
    _cachedMetrics = null;
  }
}
