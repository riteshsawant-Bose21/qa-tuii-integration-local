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

  List<OrganizationEntity> get organizations {
    if (_filteredOrganizations.isNotEmpty) {
      return _filteredOrganizations;
    }
    return _allOrganizations;
  }

  OrganizationEntity? get selectedOrganization => _selectedOrganization;
  List<OrganizationUserEntity> get organizationUsers => _organizationUsers;
  List<OrganizationProjectEntity> get organizationProjects =>
      _organizationProjects;
  String get searchQuery => _searchQuery;
  OrganizationMetrics? get metrics => _metrics;

  String get errorMessage {
    if (hasError && state is ErrorState) {
      return (state as ErrorState).message;
    }
    return '';
  }

  // Getters for filter states
  OrganizationType? get selectedType => _selectedType;
  OrganizationRegion? get selectedRegion => _selectedRegion;
  OrganizationStatus? get selectedStatus => _selectedStatus;

  Future<void> initialize() async {
    await Future.wait([loadOrganizations(), loadMetrics()]);
  }

  Future<void> loadOrganizations() async {
    try {
      setLoading();
      final organizations = await getOrganizationsUseCase(NoParams());
      _allOrganizations = organizations;
      _applyCurrentFilters();
      setLoaded(
        _filteredOrganizations.isNotEmpty
            ? _filteredOrganizations
            : _allOrganizations,
      );
    } catch (e) {
      print('Load organizations error: $e');
      setError('Failed to load organizations: ${e.toString()}');
    }
  }

  Future<void> loadMetrics() async {
    try {
      print('Loading organization metrics...');
      _metrics = await getOrganizationMetricsUseCase(NoParams());
      print(
        'Metrics loaded: distributors=${_metrics?.totalDistributors}, resellers=${_metrics?.totalResellers}, endUsers=${_metrics?.totalEndUsers}, total=${_metrics?.totalOrganizations}',
      );
      // Trigger UI update since metrics are loaded separately
      if (state is LoadedState) {
        emit(state); // Re-emit current state to trigger UI rebuild
      }
    } catch (e) {
      print('Load metrics error: $e');
      // Don't affect main loading state, but still log the error
    }
  }

  Future<void> loadOrganizationById(String id) async {
    try {
      print('🔄 Loading organization: $id');
      setLoading();

      // Clear previous organization data to prevent stale data display
      print('🗑️ Clearing previous organization data');
      _selectedOrganization = null;
      _organizationUsers = [];
      _organizationProjects = [];

      final organization = await getOrganizationByIdUseCase(id);
      _selectedOrganization = organization;
      print('✅ Loaded organization: ${organization.name} (${organization.id})');

      // Also load related data
      print('📊 Loading users and projects for org: $id');
      await Future.wait([
        loadOrganizationUsers(id),
        loadOrganizationProjects(id),
      ]);

      print(
        '🎉 Organization data loaded - Users: ${_organizationUsers.length}, Projects: ${_organizationProjects.length}',
      );
      setLoaded(
        _filteredOrganizations.isNotEmpty
            ? _filteredOrganizations
            : _allOrganizations,
      );
    } catch (e) {
      print('❌ Error loading organization $id: $e');
      setError('Failed to load organization: ${e.toString()}');
    }
  }

  Future<void> loadOrganizationUsers(String organizationId) async {
    try {
      print('👥 Loading users for organization: $organizationId');
      _organizationUsers = await getOrganizationUsersUseCase(organizationId);
      print(
        '👥 Loaded ${_organizationUsers.length} users for org: $organizationId',
      );
    } catch (e) {
      print('❌ Error loading users for org $organizationId: $e');
      // Silently handle error, don't affect main UI state
      _organizationUsers = [];
    }
  }

  Future<void> loadOrganizationProjects(String organizationId) async {
    try {
      print('🏗️ Loading projects for organization: $organizationId');
      _organizationProjects = await getOrganizationProjectsUseCase(
        organizationId,
      );
      print(
        '🏗️ Loaded ${_organizationProjects.length} projects for org: $organizationId',
      );
    } catch (e) {
      print('❌ Error loading projects for org $organizationId: $e');
      // Silently handle error, don't affect main UI state
      _organizationProjects = [];
    }
  }

  Future<void> searchOrganizations(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredOrganizations = [];
      setLoaded(_allOrganizations);
      return;
    }

    try {
      setLoading();
      final results = await searchOrganizationsUseCase(query);
      _filteredOrganizations = results;
      setLoaded(_filteredOrganizations);
    } catch (e) {
      // Fallback to local filtering
      _filterLocally();
      setLoaded(_filteredOrganizations);
    }
  }

  void _filterLocally() {
    _filteredOrganizations = _allOrganizations.where((org) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          org.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          org.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ==
              true;

      final matchesType = _selectedType == null || org.type == _selectedType;
      final matchesRegion =
          _selectedRegion == null || org.region == _selectedRegion;
      final matchesStatus =
          _selectedStatus == null || org.status == _selectedStatus;

      return matchesQuery && matchesType && matchesRegion && matchesStatus;
    }).toList();
  }

  Future<void> applyFilters({
    OrganizationType? type,
    OrganizationRegion? region,
    OrganizationStatus? status,
  }) async {
    _selectedType = type;
    _selectedRegion = region;
    _selectedStatus = status;

    await _applyCurrentFilters();
  }

  Future<void> _applyCurrentFilters() async {
    // If we have no filters and no search, show all
    if (_selectedType == null &&
        _selectedRegion == null &&
        _selectedStatus == null &&
        _searchQuery.isEmpty) {
      _filteredOrganizations = [];
      return;
    }

    try {
      // Try to use backend filtering if available
      final params = OrganizationFilterParams(
        type: _selectedType,
        region: _selectedRegion,
        status: _selectedStatus,
        searchQuery: _searchQuery,
      );

      final results = await filterOrganizationsUseCase(params);
      _filteredOrganizations = results;
    } catch (e) {
      // Fallback to local filtering
      _filterLocally();
    }
  }

  void clearFilters() {
    _selectedType = null;
    _selectedRegion = null;
    _selectedStatus = null;
    _searchQuery = '';
    _filteredOrganizations = [];
    setLoaded(_allOrganizations);
  }

  Future<void> createOrganization(OrganizationEntity organization) async {
    try {
      setLoading();
      await createOrganizationUseCase(organization);
      await loadOrganizations();
    } catch (e) {
      setError('Failed to create organization: \${e.toString()}');
    }
  }

  Future<void> updateOrganization(OrganizationEntity organization) async {
    try {
      setLoading();
      await updateOrganizationUseCase(organization);

      // Update the selected organization if it's the same one
      if (_selectedOrganization?.id == organization.id) {
        _selectedOrganization = organization;
      }

      await loadOrganizations();
    } catch (e) {
      setError('Failed to update organization: \${e.toString()}');
    }
  }

  Future<void> deleteOrganization(String id) async {
    try {
      setLoading();
      await deleteOrganizationUseCase(id);

      // Clear selected organization if it was deleted
      if (_selectedOrganization?.id == id) {
        _selectedOrganization = null;
        _organizationUsers.clear();
        _organizationProjects.clear();
      }

      await loadOrganizations();
    } catch (e) {
      setError('Failed to delete organization: \${e.toString()}');
    }
  }

  Future<void> activateOrganization(String id) async {
    try {
      setLoading();
      final updatedOrg = await activateOrganizationUseCase(id);

      // Update the selected organization if it's the same one
      if (_selectedOrganization?.id == id) {
        _selectedOrganization = updatedOrg;
      }

      await loadOrganizations();
    } catch (e) {
      setError('Failed to activate organization: \${e.toString()}');
    }
  }

  Future<void> deactivateOrganization(String id) async {
    try {
      setLoading();
      final updatedOrg = await deactivateOrganizationUseCase(id);

      // Update the selected organization if it's the same one
      if (_selectedOrganization?.id == id) {
        _selectedOrganization = updatedOrg;
      }

      await loadOrganizations();
    } catch (e) {
      setError('Failed to deactivate organization: \${e.toString()}');
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
