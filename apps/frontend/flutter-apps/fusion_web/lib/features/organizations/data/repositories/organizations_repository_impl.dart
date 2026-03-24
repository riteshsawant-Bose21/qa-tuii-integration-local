import 'package:fusion_web/features/organizations/data/datasources/organizations_datasource.dart';
import 'package:fusion_web/features/organizations/data/models/organization_model.dart';
import 'package:fusion_web/features/organizations/data/models/organization_user_model.dart';
import 'package:fusion_web/features/organizations/data/models/organization_project_model.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_entity.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_user_entity.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_project_entity.dart';
import 'package:fusion_web/features/organizations/domain/repositories/organizations_repository.dart';

class OrganizationsRepositoryImpl implements OrganizationsRepository {
  final OrganizationsRemoteDataSource remoteDataSource;
  final OrganizationsLocalDataSource localDataSource;

  const OrganizationsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  OrganizationModel _entityToModel(OrganizationEntity organization) {
    return OrganizationModel(
      id: organization.id,
      name: organization.name,
      type: organization.type,
      region: organization.region,
      status: organization.status,
      userCount: organization.userCount,
      ongoingProjectsCount: organization.ongoingProjectsCount,
      completedProjectsCount: organization.completedProjectsCount,
      createdAt: organization.createdAt,
      updatedAt: organization.updatedAt,
      description: organization.description,
      address: organization.address,
      phone: organization.phone,
      email: organization.email,
      website: organization.website,
      contactPersonName: organization.contactPersonName,
      contactPersonEmail: organization.contactPersonEmail,
      contactPersonPhone: organization.contactPersonPhone,
      userIds: organization.userIds,
      projectIds: organization.projectIds,
      isActive: organization.isActive,
    );
  }

  @override
  Future<List<OrganizationEntity>> getOrganizations() async {
    try {
      final remoteData = await remoteDataSource.getOrganizations();
      localDataSource.cacheOrganizations(remoteData);
      return remoteData;
    } catch (e) {
      try {
        return await localDataSource.getOrganizations();
      } catch (e) {
        return OrganizationModel.mockOrganizations();
      }
    }
  }

  @override
  Future<OrganizationEntity> getOrganizationById(String id) async {
    try {
      return await remoteDataSource.getOrganizationById(id);
    } catch (e) {
      try {
        return await localDataSource.getOrganizationById(id);
      } catch (e) {
        // Return mock data if not found in cache
        final mockOrgs = OrganizationModel.mockOrganizations();
        return mockOrgs.firstWhere((org) => org.id == id);
      }
    }
  }

  @override
  Future<OrganizationEntity> createOrganization(
    OrganizationEntity organization,
  ) async {
    try {
      final model = _entityToModel(organization);
      final result = await remoteDataSource.createOrganization(model);
      return result;
    } catch (e) {
      print('Failed to create organization: $e');
      rethrow;
    }
  }

  @override
  Future<OrganizationEntity> updateOrganization(
    OrganizationEntity organization,
  ) async {
    try {
      final model = _entityToModel(organization);
      final result = await remoteDataSource.updateOrganization(model);
      return result;
    } catch (e) {
      print('Failed to update organization: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteOrganization(String id) async {
    try {
      await remoteDataSource.deleteOrganization(id);
    } catch (e) {
      print('Failed to delete organization: $e');
      rethrow;
    }
  }

  @override
  Future<List<OrganizationEntity>> searchOrganizations(String query) async {
    try {
      return await remoteDataSource.searchOrganizations(query);
    } catch (e) {
      try {
        return await localDataSource.searchOrganizations(query);
      } catch (e) {
        return [];
      }
    }
  }

  @override
  Future<List<OrganizationEntity>> filterOrganizations(
    OrganizationFilterParams params,
  ) async {
    try {
      return await remoteDataSource.filterOrganizations(params);
    } catch (e) {
      try {
        return await localDataSource.filterOrganizations(params);
      } catch (e) {
        return [];
      }
    }
  }

  @override
  Future<OrganizationMetrics> getOrganizationMetrics() async {
    try {
      return await remoteDataSource.getOrganizationMetrics();
    } catch (e) {
      try {
        return await localDataSource.getOrganizationMetrics();
      } catch (e) {
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
      return await remoteDataSource.getOrganizationUsers(organizationId);
    } catch (e) {
      // Fallback to mock data
      return OrganizationUserModel.mockUsersForOrganization(organizationId);
    }
  }

  @override
  Future<List<OrganizationProjectEntity>> getOrganizationProjects(
    String organizationId,
  ) async {
    try {
      return await remoteDataSource.getOrganizationProjects(organizationId);
    } catch (e) {
      // Fallback to mock data
      return OrganizationProjectModel.mockProjectsForOrganization(
        organizationId,
      );
    }
  }

  @override
  Future<OrganizationEntity> activateOrganization(String id) async {
    try {
      return await remoteDataSource.activateOrganization(id);
    } catch (e) {
      print('Failed to activate organization: $e');
      rethrow;
    }
  }

  @override
  Future<OrganizationEntity> deactivateOrganization(String id) async {
    try {
      return await remoteDataSource.deactivateOrganization(id);
    } catch (e) {
      print('Failed to deactivate organization: $e');
      rethrow;
    }
  }
}
