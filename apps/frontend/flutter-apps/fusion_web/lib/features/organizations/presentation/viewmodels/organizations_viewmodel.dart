import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/core/usecases/usecase.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_entity.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_user_entity.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_project_entity.dart';
import 'package:fusion_web/features/organizations/domain/repositories/organizations_repository.dart';
import 'package:fusion_web/features/organizations/domain/usecases/organizations_usecases.dart';

class OrganizationsViewModel extends BaseViewModel<List<OrganizationEntity>> {
  final GetOrganizationsUseCase getOrganizationsUseCase;
  final GetOrganizationByIdUseCase getOrganizationByIdUseCase;
  final CreateOrganizationUseCase createOrganizationUseCase;
  final UpdateOrganizationUseCase updateOrganizationUseCase;
  final DeleteOrganizationUseCase deleteOrganizationUseCase;
  final SearchOrganizationsUseCase searchOrganizationsUseCase;
  final FilterOrganizationsUseCase filterOrganizationsUseCase;
  final GetOrganizationMetricsUseCase getOrganizationMetricsUseCase;
  final GetOrganizationUsersUseCase getOrganizationUsersUseCase;
  final GetOrganizationProjectsUseCase getOrganizationProjectsUseCase;
  final ActivateOrganizationUseCase activateOrganizationUseCase;
  final DeactivateOrganizationUseCase deactivateOrganizationUseCase;

  List<OrganizationEntity> _allOrganizations = [];
  List<OrganizationEntity> _filteredOrganizations = [];
  OrganizationEntity? _selectedOrganization;
  List<OrganizationUserEntity> _organizationUsers = [];
  List<OrganizationProjectEntity> _organizationProjects = [];
  String _searchQuery = '';
  OrganizationMetrics? _metrics;

  // Filter states
  OrganizationType? _selectedType;
  OrganizationRegion? _selectedRegion;
  OrganizationStatus? _selectedStatus;

  OrganizationsViewModel({
    required this.getOrganizationsUseCase,
    required this.getOrganizationByIdUseCase,
    required this.createOrganizationUseCase,
    required this.updateOrganizationUseCase,
    required this.deleteOrganizationUseCase,
    required this.searchOrganizationsUseCase,
    required this.filterOrganizationsUseCase,
    required this.getOrganizationMetricsUseCase,
    required this.getOrganizationUsersUseCase,
    required this.getOrganizationProjectsUseCase,
    required this.activateOrganizationUseCase,
    required this.deactivateOrganizationUseCase,
  });

  // Getters
  List<OrganizationEntity> get allOrganizations => _allOrganizations;
  List<OrganizationEntity> get filteredOrganizations => _filteredOrganizations;
  OrganizationEntity? get selectedOrganization => _selectedOrganization;
  List<OrganizationUserEntity> get organizationUsers => _organizationUsers;
  List<OrganizationProjectEntity> get organizationProjects =>
      _organizationProjects;
  String get searchQuery => _searchQuery;
  OrganizationMetrics? get metrics => _metrics;
  OrganizationType? get selectedType => _selectedType;
  OrganizationRegion? get selectedRegion => _selectedRegion;
  OrganizationStatus? get selectedStatus => _selectedStatus;

  // Initialize
  Future<void> initialize() async {
    await loadOrganizations();
    await loadMetrics();
  }

  // Load Organizations
  Future<void> loadOrganizations() async {
    try {
      setLoading();
      final organizations = await getOrganizationsUseCase(NoParams());
      _allOrganizations = organizations;
      _filteredOrganizations = organizations;
      setLoaded(organizations);
    } catch (e) {
      setError('Failed to load organizations: $e');
    }
  }

  // Load Metrics
  Future<void> loadMetrics() async {
    try {
      _metrics = await getOrganizationMetricsUseCase(NoParams());
      // Don't call notifyListeners() here as this is a BaseViewModel
    } catch (e) {
      print('Failed to load metrics: $e');
    }
  }

  // Load Organization by ID
  Future<void> loadOrganizationById(String id) async {
    try {
      final organization = await getOrganizationByIdUseCase(id);
      _selectedOrganization = organization;

      // Load organization users and projects
      await loadOrganizationUsers(id);
      await loadOrganizationProjects(id);

      // Don't call notifyListeners() here as this is a BaseViewModel
    } catch (e) {
      print('Failed to load organization: $e');
      setError('Failed to load organization details');
    }
  }

  // Load Organization Users
  Future<void> loadOrganizationUsers(String organizationId) async {
    try {
      _organizationUsers = await getOrganizationUsersUseCase(organizationId);
      // Don't call notifyListeners() here as this is a BaseViewModel
    } catch (e) {
      print('Failed to load organization users: $e');
    }
  }

  // Load Organization Projects
  Future<void> loadOrganizationProjects(String organizationId) async {
    try {
      _organizationProjects = await getOrganizationProjectsUseCase(
        organizationId,
      );
      // Don't call notifyListeners() here as this is a BaseViewModel
    } catch (e) {
      print('Failed to load organization projects: $e');
    }
  }

  // Search Organizations
  Future<void> searchOrganizations(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredOrganizations = _allOrganizations;
    } else {
      try {
        _filteredOrganizations = await searchOrganizationsUseCase(query);
      } catch (e) {
        // Fallback to local filtering
        _filteredOrganizations = _allOrganizations
            .where(
              (org) => org.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    }

    setLoaded(_filteredOrganizations);
  }

  // Apply Filters
  Future<void> applyFilters({
    OrganizationType? type,
    OrganizationRegion? region,
    OrganizationStatus? status,
  }) async {
    _selectedType = type;
    _selectedRegion = region;
    _selectedStatus = status;

    try {
      final params = OrganizationFilterParams(
        type: type,
        region: region,
        status: status,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      _filteredOrganizations = await filterOrganizationsUseCase(params);
      setLoaded(_filteredOrganizations);
    } catch (e) {
      // Fallback to local filtering
      _filteredOrganizations = _allOrganizations.where((org) {
        if (type != null && org.type != type) return false;
        if (region != null && org.region != region) return false;
        if (status != null && org.status != status) return false;
        if (_searchQuery.isNotEmpty &&
            !org.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          return false;
        return true;
      }).toList();

      setLoaded(_filteredOrganizations);
    }
  }

  // Clear Filters
  void clearFilters() {
    _selectedType = null;
    _selectedRegion = null;
    _selectedStatus = null;
    _searchQuery = '';
    _filteredOrganizations = _allOrganizations;
    setLoaded(_filteredOrganizations);
  }

  // Create Organization
  Future<void> createOrganization(OrganizationEntity organization) async {
    try {
      final createdOrg = await createOrganizationUseCase(organization);
      _allOrganizations.add(createdOrg);
      _filteredOrganizations = _allOrganizations;
      await loadMetrics(); // Refresh metrics
      setLoaded(_filteredOrganizations);
    } catch (e) {
      setError('Failed to create organization: $e');
    }
  }

  // Update Organization
  Future<void> updateOrganization(OrganizationEntity organization) async {
    try {
      final updatedOrg = await updateOrganizationUseCase(organization);
      final index = _allOrganizations.indexWhere(
        (org) => org.id == organization.id,
      );
      if (index != -1) {
        _allOrganizations[index] = updatedOrg;
        _filteredOrganizations = _allOrganizations;
      }
      if (_selectedOrganization?.id == organization.id) {
        _selectedOrganization = updatedOrg;
      }
      setLoaded(_filteredOrganizations);
    } catch (e) {
      setError('Failed to update organization: $e');
    }
  }

  // Delete Organization
  Future<void> deleteOrganization(String id) async {
    try {
      await deleteOrganizationUseCase(id);
      _allOrganizations.removeWhere((org) => org.id == id);
      _filteredOrganizations = _allOrganizations;
      await loadMetrics(); // Refresh metrics
      setLoaded(_filteredOrganizations);
    } catch (e) {
      setError('Failed to delete organization: $e');
    }
  }

  // Activate Organization
  Future<void> activateOrganization(String id) async {
    try {
      final activatedOrg = await activateOrganizationUseCase(id);
      final index = _allOrganizations.indexWhere((org) => org.id == id);
      if (index != -1) {
        _allOrganizations[index] = activatedOrg;
        _filteredOrganizations = _allOrganizations;
      }
      if (_selectedOrganization?.id == id) {
        _selectedOrganization = activatedOrg;
      }
      await loadMetrics(); // Refresh metrics
      setLoaded(_filteredOrganizations);
    } catch (e) {
      setError('Failed to activate organization: $e');
    }
  }

  // Deactivate Organization
  Future<void> deactivateOrganization(String id) async {
    try {
      final deactivatedOrg = await deactivateOrganizationUseCase(id);
      final index = _allOrganizations.indexWhere((org) => org.id == id);
      if (index != -1) {
        _allOrganizations[index] = deactivatedOrg;
        _filteredOrganizations = _allOrganizations;
      }
      if (_selectedOrganization?.id == id) {
        _selectedOrganization = deactivatedOrg;
      }
      await loadMetrics(); // Refresh metrics
      setLoaded(_filteredOrganizations);
    } catch (e) {
      setError('Failed to deactivate organization: $e');
    }
  }

  // Refresh Data
  Future<void> refresh() async {
    await loadOrganizations();
    await loadMetrics();
  }

  // Select Organization (for navigation purposes)
  void selectOrganization(OrganizationEntity organization) {
    _selectedOrganization = organization;
    // Don't call notifyListeners() here as this is a BaseViewModel
  }

  // Clear Selection
  void clearSelection() {
    _selectedOrganization = null;
    _organizationUsers.clear();
    _organizationProjects.clear();
    // Don't call notifyListeners() here as this is a BaseViewModel
  }
}
