import 'package:fusion_web/features/organizations/domain/entities/organization_entity.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_user_entity.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_project_entity.dart';

// Filter Parameters
class OrganizationFilterParams {
  final OrganizationType? type;
  final OrganizationRegion? region;
  final OrganizationStatus? status;
  final int? minUsers;
  final int? maxUsers;
  final String? searchQuery;

  const OrganizationFilterParams({
    this.type,
    this.region,
    this.status,
    this.minUsers,
    this.maxUsers,
    this.searchQuery,
  });
}

// Organization Metrics
class OrganizationMetrics {
  final int totalDistributors;
  final int totalResellers;
  final int totalEndUsers;
  final int totalOrganizations;

  const OrganizationMetrics({
    required this.totalDistributors,
    required this.totalResellers,
    required this.totalEndUsers,
    required this.totalOrganizations,
  });
}

// Repository interface - Domain layer doesn't know about implementation
abstract class OrganizationsRepository {
  // Organization CRUD operations
  Future<List<OrganizationEntity>> getOrganizations();
  Future<OrganizationEntity> getOrganizationById(String id);
  Future<OrganizationEntity> createOrganization(
    OrganizationEntity organization,
  );
  Future<OrganizationEntity> updateOrganization(
    OrganizationEntity organization,
  );
  Future<void> deleteOrganization(String id);

  // Search and filter operations
  Future<List<OrganizationEntity>> searchOrganizations(String query);
  Future<List<OrganizationEntity>> filterOrganizations(
    OrganizationFilterParams params,
  );

  // Metrics
  Future<OrganizationMetrics> getOrganizationMetrics();

  // Organization users
  Future<List<OrganizationUserEntity>> getOrganizationUsers(
    String organizationId,
  );

  // Organization projects
  Future<List<OrganizationProjectEntity>> getOrganizationProjects(
    String organizationId,
  );

  // Organization status operations
  Future<OrganizationEntity> activateOrganization(String id);
  Future<OrganizationEntity> deactivateOrganization(String id);
}
