import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/core/usecases/usecase.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';
import 'package:fusion_web/features/users/domain/repositories/users_repository.dart';
import 'package:fusion_web/features/users/domain/usecases/users_usecases.dart';

class UsersViewModel extends BaseViewModel {
  final GetUsersUseCase getUsersUseCase;
  final GetUserByIdUseCase getUserByIdUseCase;
  final CreateUserUseCase createUserUseCase;
  final UpdateUserUseCase updateUserUseCase;
  final DeleteUserUseCase deleteUserUseCase;
  final SearchUsersUseCase searchUsersUseCase;
  final InviteUserUseCase inviteUserUseCase;
  final ResendInviteUseCase resendInviteUseCase;
  final UpdateUserRolesUseCase updateUserRolesUseCase;
  final AssignUserToProjectsUseCase assignUserToProjectsUseCase;
  final RemoveUserFromProjectsUseCase removeUserFromProjectsUseCase;
  final ActivateUserUseCase activateUserUseCase;
  final DeactivateUserUseCase deactivateUserUseCase;
  final FilterUsersUseCase filterUsersUseCase;
  final GetUserMetricsUseCase getUserMetricsUseCase;

  List<UserEntity> _users = [];
  List<UserEntity> _filteredUsers = [];
  UserEntity? _selectedUser;
  String _searchQuery = '';
  Map<String, int> _metrics = {};
  
  // Filter states
  String? _selectedRole;
  UserStatus? _selectedStatus;
  UserType? _selectedUserType;
  String? _selectedProjectId;

  UsersViewModel({
    required this.getUsersUseCase,
    required this.getUserByIdUseCase,
    required this.createUserUseCase,
    required this.updateUserUseCase,
    required this.deleteUserUseCase,
    required this.searchUsersUseCase,
    required this.inviteUserUseCase,
    required this.resendInviteUseCase,
    required this.updateUserRolesUseCase,
    required this.assignUserToProjectsUseCase,
    required this.removeUserFromProjectsUseCase,
    required this.activateUserUseCase,
    required this.deactivateUserUseCase,
    required this.filterUsersUseCase,
    required this.getUserMetricsUseCase,
  });

  List<UserEntity> get users {
    if (_filteredUsers.isNotEmpty) {
      return _filteredUsers;
    }
    return _users;
  }

  UserEntity? get selectedUser => _selectedUser;
  String get searchQuery => _searchQuery;
  Map<String, int> get metrics => _metrics;
  
  String get errorMessage {
    if (hasError && state is ErrorState) {
      return (state as ErrorState).message;
    }
    return '';
  }
  
  // Getters for filter states
  String? get selectedRole => _selectedRole;
  UserStatus? get selectedStatus => _selectedStatus;
  UserType? get selectedUserType => _selectedUserType;
  String? get selectedProjectId => _selectedProjectId;

  Future<void> loadUsers() async {
    try {
      setLoading();
      final users = await getUsersUseCase(const NoParams());
      _users = users;
      _filteredUsers = [];
      await loadMetrics();
      setLoaded(users);
    } catch (e) {
      _users = [];
      _filteredUsers = [];
      setError('Failed to load users: ${e.toString()}');
    }
  }

  Future<void> loadMetrics() async {
    try {
      _metrics = await getUserMetricsUseCase(const NoParams());
      notifyListeners();
    } catch (e) {
      print('Failed to load metrics: $e');
    }
  }

  Future<void> searchUsers(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredUsers = [];
      notifyListeners();
      return;
    }

    try {
      final results = await searchUsersUseCase(query);
      _filteredUsers = results;
      notifyListeners();
    } catch (e) {
      _filteredUsers = _users
          .where(
            (u) =>
                u.name.toLowerCase().contains(query.toLowerCase()) ||
                u.email.toLowerCase().contains(query.toLowerCase()) ||
                u.roles.any((role) => role.toLowerCase().contains(query.toLowerCase())),
          )
          .toList();
      notifyListeners();
    }
  }

  Future<void> applyFilters({
    String? role,
    UserStatus? status,
    UserType? userType,
    String? projectId,
  }) async {
    _selectedRole = role;
    _selectedStatus = status;
    _selectedUserType = userType;
    _selectedProjectId = projectId;

    final params = UserFilterParams(
      role: role,
      status: status,
      userType: userType,
      projectId: projectId,
      lastLoginStart: null,
      lastLoginEnd: null,
    );

    try {
      final results = await filterUsersUseCase(params);
      _filteredUsers = results;
      notifyListeners();
    } catch (e) {
      // Fallback to local filtering
      _filteredUsers = _users.where((user) {
        if (role != null && !user.roles.contains(role)) return false;
        if (status != null && user.status != status) return false;
        if (userType != null && user.userType != userType) return false;
        if (projectId != null && !user.associatedProjects.contains(projectId)) return false;
        return true;
      }).toList();
      notifyListeners();
    }
  }

  void clearFilters() {
    _selectedRole = null;
    _selectedStatus = null;
    _selectedUserType = null;
    _selectedProjectId = null;
    _filteredUsers = [];
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> getUser(String id) async {
    try {
      setLoading();
      final user = await getUserByIdUseCase(id);
      _selectedUser = user;
      setLoaded(user);
    } catch (e) {
      setError('Failed to load user: ${e.toString()}');
    }
  }

  Future<void> createUser(UserEntity user) async {
    try {
      setLoading();
      await createUserUseCase(user);
      await loadUsers();
    } catch (e) {
      setError('Failed to create user: ${e.toString()}');
    }
  }

  Future<void> inviteUser({
    required String email,
    required String name,
    required List<String> roles,
    List<String> projectIds = const [],
    required UserType userType,
  }) async {
    try {
      setLoading();
      final params = InviteUserParams(
        email: email,
        name: name,
        roles: roles,
        projectIds: projectIds,
        userType: userType,
      );
      await inviteUserUseCase(params);
      await loadUsers();
      setLoaded(null);
    } catch (e) {
      setError('Failed to invite user: ${e.toString()}');
    }
  }

  Future<void> resendInvite(String userId) async {
    try {
      await resendInviteUseCase(userId);
      // Show success message
    } catch (e) {
      setError('Failed to resend invite: ${e.toString()}');
    }
  }

  Future<void> updateUser(UserEntity user) async {
    try {
      setLoading();
      await updateUserUseCase(user);
      await loadUsers();
    } catch (e) {
      setError('Failed to update user: ${e.toString()}');
    }
  }

  Future<void> updateUserRoles(String userId, List<String> roles) async {
    try {
      setLoading();
      final params = UpdateUserRoleParams(userId: userId, roles: roles);
      await updateUserRolesUseCase(params);
      await loadUsers();
    } catch (e) {
      setError('Failed to update user roles: ${e.toString()}');
    }
  }

  Future<void> assignToProjects(String userId, List<String> projectIds) async {
    try {
      setLoading();
      final params = AssignUserToProjectsParams(
        userId: userId,
        projectIds: projectIds,
      );
      await assignUserToProjectsUseCase(params);
      await loadUsers();
    } catch (e) {
      setError('Failed to assign projects: ${e.toString()}');
    }
  }

  Future<void> removeFromProjects(String userId, List<String> projectIds) async {
    try {
      setLoading();
      final params = RemoveUserFromProjectsParams(
        userId: userId,
        projectIds: projectIds,
      );
      await removeUserFromProjectsUseCase(params);
      await loadUsers();
    } catch (e) {
      setError('Failed to remove from projects: ${e.toString()}');
    }
  }

  Future<void> activateUser(String userId) async {
    try {
      setLoading();
      await activateUserUseCase(userId);
      await loadUsers();
    } catch (e) {
      setError('Failed to activate user: ${e.toString()}');
    }
  }

  Future<void> deactivateUser(String userId) async {
    try {
      setLoading();
      await deactivateUserUseCase(userId);
      await loadUsers();
    } catch (e) {
      setError('Failed to deactivate user: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      setLoading();
      await deleteUserUseCase(id);
      await loadUsers();
    } catch (e) {
      setError('Failed to delete user: ${e.toString()}');
    }
  }

  void initialize() {
    loadUsers();
  }

  void selectUser(UserEntity user) {
    _selectedUser = user;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredUsers = [];
    notifyListeners();
  }
}
