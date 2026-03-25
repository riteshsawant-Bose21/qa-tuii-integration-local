import 'package:fusion_web/features/organizations/data/datasources/organizations_datasource.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_entity.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_user_entity.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_project_entity.dart';
import 'package:fusion_web/features/organizations/domain/repositories/organizations_repository.dart';

class OrganizationsRepositoryImpl implements OrganizationsRepository {
  final OrganizationsDataSource remoteDataSource;
  final OrganizationsDataSource localDataSource;

  const OrganizationsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<OrganizationEntity>> getOrganizations() async {
    try {
      // Try to get from remote first
      final remoteOrganizations = await remoteDataSource.getOrganizations();
      final organizationEntities = remoteOrganizations
          .map((model) => model.toEntity())
          .toList();

      // Cache the results locally
      if (localDataSource is OrganizationsLocalDataSource) {
        (localDataSource as OrganizationsLocalDataSource).cacheOrganizations(
          remoteOrganizations,
        );
      }

      return organizationEntities;
    } catch (e) {
      // Fallback to local cache
      try {
        final cachedOrganizations = await localDataSource.getOrganizations();
        return cachedOrganizations.map((model) => model.toEntity()).toList();
      } catch (cacheError) {
        // If both remote and cache fail, return empty list
        return [];
      }
    }
  }

  @override
  Future<OrganizationEntity> getOrganizationById(String id) async {
    try {
      // Try remote first
      final organizationModel = await remoteDataSource.getOrganizationById(id);
      return organizationModel.toEntity();
    } catch (e) {
      // Fallback to cache
      try {
        final cachedOrganization = await localDataSource.getOrganizationById(
          id,
        );
        return cachedOrganization.toEntity();
      } catch (cacheError) {
        throw Exception('Organization with id \$id not found');
      }
    }
  }

  @override
  Future<OrganizationEntity> createOrganization(
    OrganizationEntity organization,
  ) async {
    try {
      final organizationModel = await remoteDataSource.createOrganization(
        organization,
      );

      // Refresh local cache after successful creation
      _refreshCacheInBackground();

      return organizationModel.toEntity();
    } catch (e) {
      throw Exception('Failed to create organization: \${e.toString()}');
    }
  }

  @override
  Future<OrganizationEntity> updateOrganization(
    OrganizationEntity organization,
  ) async {
    try {
      final organizationModel = await remoteDataSource.updateOrganization(
        organization,
      );

      // Refresh local cache after successful update
      _refreshCacheInBackground();

      return organizationModel.toEntity();
    } catch (e) {
      throw Exception('Failed to update organization: \${e.toString()}');
    }
  }

  @override
  Future<bool> deleteOrganization(String id) async {
    try {
      final success = await remoteDataSource.deleteOrganization(id);

      if (success) {
        // Refresh local cache after successful deletion
        _refreshCacheInBackground();
      }

      return success;
    } catch (e) {
      throw Exception('Failed to delete organization: \${e.toString()}');
    }
  }

  @override
  Future<List<OrganizationEntity>> searchOrganizations(String query) async {
    try {
      // Try remote search first
      final remoteOrganizations = await remoteDataSource.searchOrganizations(
        query,
      );
      return remoteOrganizations.map((model) => model.toEntity()).toList();
    } catch (e) {
      // Fallback to local search
      try {
        final cachedResults = await localDataSource.searchOrganizations(query);
        return cachedResults.map((model) => model.toEntity()).toList();
      } catch (cacheError) {
        return [];
      }
    }
  }

  @override
  Future<List<OrganizationEntity>> filterOrganizations(
    OrganizationFilterParams params,
  ) async {
    try {
      // Try remote filtering first
      final remoteOrganizations = await remoteDataSource.filterOrganizations(
        params,
      );
      return remoteOrganizations.map((model) => model.toEntity()).toList();
    } catch (e) {
      // Fallback to local filtering
      try {
        final cachedResults = await localDataSource.filterOrganizations(params);
        return cachedResults.map((model) => model.toEntity()).toList();
      } catch (cacheError) {
        return [];
      }
    }
  }

  @override
  Future<OrganizationMetrics> getOrganizationMetrics() async {
    try {
      // Try to get metrics from remote
      final metrics = await remoteDataSource.getOrganizationMetrics();

      // Cache the metrics locally
      if (localDataSource is OrganizationsLocalDataSource) {
        (localDataSource as OrganizationsLocalDataSource).cacheMetrics(metrics);
      }

      return metrics;
    } catch (e) {
      // Fallback to cached metrics
      try {
        return await localDataSource.getOrganizationMetrics();
      } catch (cacheError) {
        // Return default metrics if both fail
        return const OrganizationMetrics(
          totalDistributors: 0,
          totalResellers: 0,
          totalEndUsers: 0,
          totalOrganizations: 0,
        );
      }
    }
  }

  @override
  Future<List<OrganizationUserEntity>> getOrganizationUsers(
    String organizationId,
  ) async {
    try {
      final userModels = await remoteDataSource.getOrganizationUsers(
        organizationId,
      );
      return userModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      // Fallback to local cache (though it may be empty)
      try {
        final cachedUsers = await localDataSource.getOrganizationUsers(
          organizationId,
        );
        return cachedUsers.map((model) => model.toEntity()).toList();
      } catch (cacheError) {
        return [];
      }
    }
  }

  @override
  Future<List<OrganizationProjectEntity>> getOrganizationProjects(
    String organizationId,
  ) async {
    try {
      final projectModels = await remoteDataSource.getOrganizationProjects(
        organizationId,
      );
      return projectModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      // Fallback to local cache (though it may be empty)
      try {
        final cachedProjects = await localDataSource.getOrganizationProjects(
          organizationId,
        );
        return cachedProjects.map((model) => model.toEntity()).toList();
      } catch (cacheError) {
        return [];
      }
    }
  }

  @override
  Future<OrganizationEntity> activateOrganization(String id) async {
    try {
      final organizationModel = await remoteDataSource.activateOrganization(id);

      // Refresh local cache after successful activation
      _refreshCacheInBackground();

      return organizationModel.toEntity();
    } catch (e) {
      throw Exception('Failed to activate organization: \${e.toString()}');
    }
  }

  @override
  Future<OrganizationEntity> deactivateOrganization(String id) async {
    try {
      final organizationModel = await remoteDataSource.deactivateOrganization(
        id,
      );

      // Refresh local cache after successful deactivation
      _refreshCacheInBackground();

      return organizationModel.toEntity();
    } catch (e) {
      throw Exception('Failed to deactivate organization: \${e.toString()}');
    }
  }

  // Helper method to refresh cache in background
  void _refreshCacheInBackground() {
    // Run cache refresh in background without awaiting
    Future.microtask(() async {
      try {
        final remoteOrganizations = await remoteDataSource.getOrganizations();
        if (localDataSource is OrganizationsLocalDataSource) {
          (localDataSource as OrganizationsLocalDataSource).cacheOrganizations(
            remoteOrganizations,
          );
        }
      } catch (e) {
        // Silently handle cache refresh errors
      }
    });
  }

  // Additional utility methods
  Future<void> clearCache() async {
    if (localDataSource is OrganizationsLocalDataSource) {
      (localDataSource as OrganizationsLocalDataSource).clearCache();
    }
  }
}
