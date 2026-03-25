import 'package:fusion_web/core/usecases/usecase.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_entity.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_user_entity.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_project_entity.dart';
import 'package:fusion_web/features/organizations/domain/repositories/organizations_repository.dart';

// Get Organizations Use Case
class GetOrganizationsUseCase
    implements UseCase<List<OrganizationEntity>, NoParams> {
  final OrganizationsRepository repository;

  const GetOrganizationsUseCase(this.repository);

  @override
  Future<List<OrganizationEntity>> call(NoParams params) async {
    return await repository.getOrganizations();
  }
}

// Get Organization By ID Use Case
class GetOrganizationByIdUseCase
    implements UseCase<OrganizationEntity, String> {
  final OrganizationsRepository repository;

  const GetOrganizationByIdUseCase(this.repository);

  @override
  Future<OrganizationEntity> call(String id) async {
    return await repository.getOrganizationById(id);
  }
}

// Create Organization Use Case
class CreateOrganizationUseCase
    implements UseCase<OrganizationEntity, OrganizationEntity> {
  final OrganizationsRepository repository;

  const CreateOrganizationUseCase(this.repository);

  @override
  Future<OrganizationEntity> call(OrganizationEntity organization) async {
    return await repository.createOrganization(organization);
  }
}

// Update Organization Use Case
class UpdateOrganizationUseCase
    implements UseCase<OrganizationEntity, OrganizationEntity> {
  final OrganizationsRepository repository;

  const UpdateOrganizationUseCase(this.repository);

  @override
  Future<OrganizationEntity> call(OrganizationEntity organization) async {
    return await repository.updateOrganization(organization);
  }
}

// Delete Organization Use Case
class DeleteOrganizationUseCase implements UseCase<void, String> {
  final OrganizationsRepository repository;

  const DeleteOrganizationUseCase(this.repository);

  @override
  Future<void> call(String id) async {
    return await repository.deleteOrganization(id);
  }
}

// Search Organizations Use Case
class SearchOrganizationsUseCase
    implements UseCase<List<OrganizationEntity>, String> {
  final OrganizationsRepository repository;

  const SearchOrganizationsUseCase(this.repository);

  @override
  Future<List<OrganizationEntity>> call(String query) async {
    return await repository.searchOrganizations(query);
  }
}

// Filter Organizations Use Case
class FilterOrganizationsUseCase
    implements UseCase<List<OrganizationEntity>, OrganizationFilterParams> {
  final OrganizationsRepository repository;

  const FilterOrganizationsUseCase(this.repository);

  @override
  Future<List<OrganizationEntity>> call(OrganizationFilterParams params) async {
    return await repository.filterOrganizations(params);
  }
}

// Get Organization Metrics Use Case
class GetOrganizationMetricsUseCase
    implements UseCase<OrganizationMetrics, NoParams> {
  final OrganizationsRepository repository;

  const GetOrganizationMetricsUseCase(this.repository);

  @override
  Future<OrganizationMetrics> call(NoParams params) async {
    return await repository.getOrganizationMetrics();
  }
}

// Get Organization Users Use Case
class GetOrganizationUsersUseCase
    implements UseCase<List<OrganizationUserEntity>, String> {
  final OrganizationsRepository repository;

  const GetOrganizationUsersUseCase(this.repository);

  @override
  Future<List<OrganizationUserEntity>> call(String organizationId) async {
    return await repository.getOrganizationUsers(organizationId);
  }
}

// Get Organization Projects Use Case
class GetOrganizationProjectsUseCase
    implements UseCase<List<OrganizationProjectEntity>, String> {
  final OrganizationsRepository repository;

  const GetOrganizationProjectsUseCase(this.repository);

  @override
  Future<List<OrganizationProjectEntity>> call(String organizationId) async {
    return await repository.getOrganizationProjects(organizationId);
  }
}

// Activate Organization Use Case
class ActivateOrganizationUseCase
    implements UseCase<OrganizationEntity, String> {
  final OrganizationsRepository repository;

  const ActivateOrganizationUseCase(this.repository);

  @override
  Future<OrganizationEntity> call(String id) async {
    return await repository.activateOrganization(id);
  }
}

// Deactivate Organization Use Case
class DeactivateOrganizationUseCase
    implements UseCase<OrganizationEntity, String> {
  final OrganizationsRepository repository;

  const DeactivateOrganizationUseCase(this.repository);

  @override
  Future<OrganizationEntity> call(String id) async {
    return await repository.deactivateOrganization(id);
  }
}
