import 'package:fusion_web/features/organizations/data/models/organization_model.dart';
import 'package:fusion_web/features/organizations/data/models/organization_user_model.dart';
import 'package:fusion_web/features/organizations/data/models/organization_project_model.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_entity.dart';
import 'package:fusion_web/features/organizations/domain/repositories/organizations_repository.dart';
import 'package:fusion_web/core/services/api_service.dart';

abstract class OrganizationsDataSource {
  Future<List<OrganizationModel>> getOrganizations();
  Future<OrganizationModel> getOrganizationById(String id);
  Future<OrganizationModel> createOrganization(OrganizationModel organization);
  Future<OrganizationModel> updateOrganization(OrganizationModel organization);
  Future<void> deleteOrganization(String id);
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
  final ApiService _apiService;

  OrganizationsRemoteDataSource({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  @override
  Future<List<OrganizationModel>> getOrganizations() async {
    try {
      print('Organizations API: Calling organizations endpoint');
      // For now, return mock data since the API might not be implemented yet
      return OrganizationModel.mockOrganizations();

      // When API is ready, use this:
      // final response = await _apiService.get('/organizations');
      // final organizationsJson = response['data'] as List<dynamic>;
      // return organizationsJson.map((json) => OrganizationModel.fromJson(json)).toList();
    } catch (e) {
      print('Organizations API error: $e');
      return OrganizationModel.mockOrganizations();
    }
  }

  @override
  Future<OrganizationModel> getOrganizationById(String id) async {
    try {
      print('Organizations API: Getting organization by id: $id');
      // For now, return mock data
      final organizations = OrganizationModel.mockOrganizations();
      final organization = organizations.firstWhere((org) => org.id == id);
      return organization;

      // When API is ready, use this:
      // final response = await _apiService.get('/organizations/$id');
      // return OrganizationModel.fromJson(response['data']);
    } catch (e) {
      print('Organizations API error: $e');
      throw Exception('Organization not found');
    }
  }

  @override
  Future<OrganizationModel> createOrganization(
    OrganizationModel organization,
  ) async {
    try {
      print('Organizations API: Creating organization: ${organization.name}');
      // For now, just return the organization with a new ID
      return organization.copyWith(
        id: 'org-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
      );

      // When API is ready, use this:
      // final response = await _apiService.post('/organizations', organization.toJson());
      // return OrganizationModel.fromJson(response['data']);
    } catch (e) {
      print('Organizations API error: $e');
      throw Exception('Failed to create organization');
    }
  }

  @override
  Future<OrganizationModel> updateOrganization(
    OrganizationModel organization,
  ) async {
    try {
      print('Organizations API: Updating organization: ${organization.id}');
      // For now, just return the updated organization
      return organization.copyWith(updatedAt: DateTime.now());

      // When API is ready, use this:
      // final response = await _apiService.put('/organizations/${organization.id}', organization.toJson());
      // return OrganizationModel.fromJson(response['data']);
    } catch (e) {
      print('Organizations API error: $e');
      throw Exception('Failed to update organization');
    }
  }

  @override
  Future<void> deleteOrganization(String id) async {
    try {
      print('Organizations API: Deleting organization: $id');
      // For now, just simulate success

      // When API is ready, use this:
      // await _apiService.delete('/organizations/$id');
    } catch (e) {
      print('Organizations API error: $e');
      throw Exception('Failed to delete organization');
    }
  }

  @override
  Future<List<OrganizationModel>> searchOrganizations(String query) async {
    try {
      print('Organizations API: Searching organizations with query: $query');
      // For now, filter mock data
      final organizations = OrganizationModel.mockOrganizations();
      return organizations
          .where((org) => org.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

      // When API is ready, use this:
      // final response = await _apiService.get('/organizations/search?query=$query');
      // final organizationsJson = response['data'] as List<dynamic>;
      // return organizationsJson.map((json) => OrganizationModel.fromJson(json)).toList();
    } catch (e) {
      print('Organizations API error: $e');
      return [];
    }
  }

  @override
  Future<List<OrganizationModel>> filterOrganizations(
    OrganizationFilterParams params,
  ) async {
    try {
      print('Organizations API: Filtering organizations');
      // For now, filter mock data
      final organizations = OrganizationModel.mockOrganizations();
      var filtered = organizations.where((org) {
        if (params.type != null && org.type != params.type) return false;
        if (params.region != null && org.region != params.region) return false;
        if (params.status != null && org.status != params.status) return false;
        if (params.minUsers != null && org.userCount < params.minUsers!)
          return false;
        if (params.maxUsers != null && org.userCount > params.maxUsers!)
          return false;
        if (params.searchQuery != null &&
            !org.name.toLowerCase().contains(params.searchQuery!.toLowerCase()))
          return false;
        return true;
      }).toList();

      return filtered;

      // When API is ready, use this:
      // final queryParams = <String, dynamic>{};
      // if (params.type != null) queryParams['type'] = params.type!.name;
      // if (params.region != null) queryParams['region'] = params.region!.name;
      // // ... add other params
      // final response = await _apiService.get('/organizations/filter', queryParams);
      // final organizationsJson = response['data'] as List<dynamic>;
      // return organizationsJson.map((json) => OrganizationModel.fromJson(json)).toList();
    } catch (e) {
      print('Organizations API error: $e');
      return [];
    }
  }

  @override
  Future<OrganizationMetrics> getOrganizationMetrics() async {
    try {
      print('Organizations API: Getting organization metrics');
      // For now, calculate from mock data
      final organizations = OrganizationModel.mockOrganizations();
      final totalDistributors = organizations
          .where((org) => org.type == OrganizationType.distributor)
          .length;
      final totalResellers = organizations
          .where((org) => org.type == OrganizationType.reseller)
          .length;
      final totalEndUsers = organizations
          .where((org) => org.type == OrganizationType.endUser)
          .length;

      return OrganizationMetrics(
        totalDistributors: totalDistributors,
        totalResellers: totalResellers,
        totalEndUsers: totalEndUsers,
        totalOrganizations: organizations.length,
      );

      // When API is ready, use this:
      // final response = await _apiService.get('/organizations/metrics');
      // return OrganizationMetrics.fromJson(response['data']);
    } catch (e) {
      print('Organizations API error: $e');
      return const OrganizationMetrics(
        totalDistributors: 0,
        totalResellers: 0,
        totalEndUsers: 0,
        totalOrganizations: 0,
      );
    }
  }

  @override
  Future<List<OrganizationUserModel>> getOrganizationUsers(
    String organizationId,
  ) async {
    try {
      print(
        'Organizations API: Getting users for organization: $organizationId',
      );
      // For now, return mock data
      return OrganizationUserModel.mockUsersForOrganization(organizationId);

      // When API is ready, use this:
      // final response = await _apiService.get('/organizations/$organizationId/users');
      // final usersJson = response['data'] as List<dynamic>;
      // return usersJson.map((json) => OrganizationUserModel.fromJson(json)).toList();
    } catch (e) {
      print('Organizations API error: $e');
      return [];
    }
  }

  @override
  Future<List<OrganizationProjectModel>> getOrganizationProjects(
    String organizationId,
  ) async {
    try {
      print(
        'Organizations API: Getting projects for organization: $organizationId',
      );
      // For now, return mock data
      return OrganizationProjectModel.mockProjectsForOrganization(
        organizationId,
      );

      // When API is ready, use this:
      // final response = await _apiService.get('/organizations/$organizationId/projects');
      // final projectsJson = response['data'] as List<dynamic>;
      // return projectsJson.map((json) => OrganizationProjectModel.fromJson(json)).toList();
    } catch (e) {
      print('Organizations API error: $e');
      return [];
    }
  }

  @override
  Future<OrganizationModel> activateOrganization(String id) async {
    try {
      print('Organizations API: Activating organization: $id');
      final organization = await getOrganizationById(id);
      return organization.copyWith(
        status: OrganizationStatus.active,
        updatedAt: DateTime.now(),
      );

      // When API is ready, use this:
      // final response = await _apiService.post('/organizations/$id/activate', {});
      // return OrganizationModel.fromJson(response['data']);
    } catch (e) {
      print('Organizations API error: $e');
      throw Exception('Failed to activate organization');
    }
  }

  @override
  Future<OrganizationModel> deactivateOrganization(String id) async {
    try {
      print('Organizations API: Deactivating organization: $id');
      final organization = await getOrganizationById(id);
      return organization.copyWith(
        status: OrganizationStatus.inactive,
        updatedAt: DateTime.now(),
      );

      // When API is ready, use this:
      // final response = await _apiService.post('/organizations/$id/deactivate', {});
      // return OrganizationModel.fromJson(response['data']);
    } catch (e) {
      print('Organizations API error: $e');
      throw Exception('Failed to deactivate organization');
    }
  }
}

class OrganizationsLocalDataSource implements OrganizationsDataSource {
  List<OrganizationModel> _cachedOrganizations = [];

  void cacheOrganizations(List<OrganizationModel> organizations) {
    _cachedOrganizations = organizations;
  }

  @override
  Future<List<OrganizationModel>> getOrganizations() async {
    return _cachedOrganizations;
  }

  @override
  Future<OrganizationModel> getOrganizationById(String id) async {
    return _cachedOrganizations.firstWhere((org) => org.id == id);
  }

  // Other methods would throw exceptions for local data source
  @override
  Future<OrganizationModel> createOrganization(
    OrganizationModel organization,
  ) async {
    throw UnimplementedError(
      'Create operation not available in local data source',
    );
  }

  @override
  Future<OrganizationModel> updateOrganization(
    OrganizationModel organization,
  ) async {
    throw UnimplementedError(
      'Update operation not available in local data source',
    );
  }

  @override
  Future<void> deleteOrganization(String id) async {
    throw UnimplementedError(
      'Delete operation not available in local data source',
    );
  }

  @override
  Future<List<OrganizationModel>> searchOrganizations(String query) async {
    return _cachedOrganizations
        .where((org) => org.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<OrganizationModel>> filterOrganizations(
    OrganizationFilterParams params,
  ) async {
    return _cachedOrganizations.where((org) {
      if (params.type != null && org.type != params.type) return false;
      if (params.region != null && org.region != params.region) return false;
      if (params.status != null && org.status != params.status) return false;
      return true;
    }).toList();
  }

  @override
  Future<OrganizationMetrics> getOrganizationMetrics() async {
    final totalDistributors = _cachedOrganizations
        .where((org) => org.type == OrganizationType.distributor)
        .length;
    final totalResellers = _cachedOrganizations
        .where((org) => org.type == OrganizationType.reseller)
        .length;
    final totalEndUsers = _cachedOrganizations
        .where((org) => org.type == OrganizationType.endUser)
        .length;

    return OrganizationMetrics(
      totalDistributors: totalDistributors,
      totalResellers: totalResellers,
      totalEndUsers: totalEndUsers,
      totalOrganizations: _cachedOrganizations.length,
    );
  }

  @override
  Future<List<OrganizationUserModel>> getOrganizationUsers(
    String organizationId,
  ) async {
    throw UnimplementedError(
      'Organization users not available in local data source',
    );
  }

  @override
  Future<List<OrganizationProjectModel>> getOrganizationProjects(
    String organizationId,
  ) async {
    throw UnimplementedError(
      'Organization projects not available in local data source',
    );
  }

  @override
  Future<OrganizationModel> activateOrganization(String id) async {
    throw UnimplementedError(
      'Activate operation not available in local data source',
    );
  }

  @override
  Future<OrganizationModel> deactivateOrganization(String id) async {
    throw UnimplementedError(
      'Deactivate operation not available in local data source',
    );
  }
}
