import 'package:fusion_web/features/users/data/models/user_model.dart';
import 'package:fusion_web/features/users/domain/repositories/users_repository.dart';
import 'package:fusion_web/core/services/api_service.dart';

abstract class UsersDataSource {
  Future<List<UserModel>> getUsers();
  Future<UserModel> getUserById(String id);
  Future<UserModel> createUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String id);
  Future<List<UserModel>> searchUsers(String query);
  
  // New methods
  Future<UserModel> inviteUser(InviteUserParams params);
  Future<void> resendInvite(String userId);
  Future<UserModel> updateUserRoles(UpdateUserRoleParams params);
  Future<UserModel> assignUserToProjects(String userId, List<String> projectIds);
  Future<UserModel> removeUserFromProjects(String userId, List<String> projectIds);
  Future<UserModel> activateUser(String userId);
  Future<UserModel> deactivateUser(String userId);
  Future<List<UserModel>> filterUsers(UserFilterParams params);
  Future<Map<String, int>> getUserMetrics();
}

class UsersRemoteDataSource implements UsersDataSource {
  final ApiService _apiService;

  UsersRemoteDataSource({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  @override
  Future<List<UserModel>> getUsers() async {
    try {
      print('Users API: Calling organization/users endpoint');
      final response = await _apiService.get('organization/users');

      // Debug: Print the full response structure
      print('API Response keys: ${response.keys.toList()}');
      print('API Response: $response');

      final usersJson =
          response['data'] as List<dynamic>? ??
          response['users'] as List<dynamic>? ??
          response['items'] as List<dynamic>? ??
          [];

      print('Users array length: ${usersJson.length}');

      if (usersJson.isNotEmpty) {
        print('First user sample: ${usersJson.first}');
      }

      return usersJson
          .map((json) {
            try {
              return UserModel.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing user: $json, Error: $e');
              return null;
            }
          })
          .where((user) => user != null)
          .cast<UserModel>()
          .toList();
    } catch (e) {
      // Fallback to mock data if API fails
      print('API Error, using mock data: $e');
      return UserModel.mockUsers();
    }
  }

  @override
  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _apiService.get('organization/users/$id');
      final userData =
          response['data'] as Map<String, dynamic>? ??
          response['user'] as Map<String, dynamic>? ??
          response;

      return UserModel.fromJson(userData);
    } catch (e) {
      // Fallback to mock data if API fails
      print('API Error, using mock data: $e');
      final users = UserModel.mockUsers();
      return users.firstWhere((u) => u.id == id);
    }
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    try {
      final response = await _apiService.post(
        'organization/users',
        user.toJson(),
      );
      final userData =
          response['data'] as Map<String, dynamic>? ??
          response['user'] as Map<String, dynamic>? ??
          response;

      return UserModel.fromJson(userData);
    } catch (e) {
      // Fallback behavior - return the user as-is for demo
      print('API Error, simulating creation: $e');
      await Future.delayed(const Duration(milliseconds: 800));
      return user;
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await _apiService.put(
        'organization/users/${user.id}',
        user.toJson(),
      );
      final userData =
          response['data'] as Map<String, dynamic>? ??
          response['user'] as Map<String, dynamic>? ??
          response;

      return UserModel.fromJson(userData);
    } catch (e) {
      // Fallback behavior - return the user as-is for demo
      print('API Error, simulating update: $e');
      await Future.delayed(const Duration(milliseconds: 600));
      return user;
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _apiService.delete('organization/users/$id');
    } catch (e) {
      // Fallback behavior - simulate success for demo
      print('API Error, simulating deletion: $e');
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _apiService.get(
        'organization/users/search?q=${Uri.encodeComponent(query)}',
      );
      final usersJson =
          response['data'] as List<dynamic>? ??
          response['users'] as List<dynamic>? ??
          [];

      return usersJson
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to local search on mock data
      print('API Error, using mock search: $e');
      final users = UserModel.mockUsers();
      return users
          .where(
            (u) =>
                u.name.toLowerCase().contains(query.toLowerCase()) ||
                u.email.toLowerCase().contains(query.toLowerCase()) ||
                u.role.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  @override
  Future<UserModel> inviteUser(InviteUserParams params) async {
    try {
      final response = await _apiService.post(
        'organization/users/invite',
        {
          'email': params.email,
          'name': params.name,
          'roles': params.roles,
          'project_ids': params.projectIds,
          'user_type': params.userType.displayName,
        },
      );
      final userData = response['data'] as Map<String, dynamic>? ?? response;
      return UserModel.fromJson(userData);
    } catch (e) {
      print('API Error, simulating invite: $e');
      throw Exception('Failed to invite user: $e');
    }
  }

  @override
  Future<void> resendInvite(String userId) async {
    try {
      await _apiService.post('organization/users/$userId/resend-invite', {});
    } catch (e) {
      print('API Error, simulating resend invite: $e');
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  Future<UserModel> updateUserRoles(UpdateUserRoleParams params) async {
    try {
      final response = await _apiService.put(
        'organization/users/${params.userId}/roles',
        {'roles': params.roles},
      );
      final userData = response['data'] as Map<String, dynamic>? ?? response;
      return UserModel.fromJson(userData);
    } catch (e) {
      print('API Error, simulating role update: $e');
      throw Exception('Failed to update roles: $e');
    }
  }

  @override
  Future<UserModel> assignUserToProjects(String userId, List<String> projectIds) async {
    try {
      final response = await _apiService.post(
        'organization/users/$userId/projects',
        {'project_ids': projectIds},
      );
      final userData = response['data'] as Map<String, dynamic>? ?? response;
      return UserModel.fromJson(userData);
    } catch (e) {
      print('API Error, simulating project assignment: $e');
      throw Exception('Failed to assign projects: $e');
    }
  }

  @override
  Future<UserModel> removeUserFromProjects(String userId, List<String> projectIds) async {
    try {
      await _apiService.delete('organization/users/$userId/projects');
      // For now, fetch the updated user since delete doesn't return data
      final response = await _apiService.get('organization/users/$userId');
      final userData = response['data'] as Map<String, dynamic>? ?? response;
      return UserModel.fromJson(userData);
    } catch (e) {
      print('API Error, simulating project removal: $e');
      throw Exception('Failed to remove projects: $e');
    }
  }

  @override
  Future<UserModel> activateUser(String userId) async {
    try {
      final response = await _apiService.post(
        'organization/users/$userId/activate',
        {},
      );
      final userData = response['data'] as Map<String, dynamic>? ?? response;
      return UserModel.fromJson(userData);
    } catch (e) {
      print('API Error, simulating user activation: $e');
      throw Exception('Failed to activate user: $e');
    }
  }

  @override
  Future<UserModel> deactivateUser(String userId) async {
    try {
      final response = await _apiService.post(
        'organization/users/$userId/deactivate',
        {},
      );
      final userData = response['data'] as Map<String, dynamic>? ?? response;
      return UserModel.fromJson(userData);
    } catch (e) {
      print('API Error, simulating user deactivation: $e');
      throw Exception('Failed to deactivate user: $e');
    }
  }

  @override
  Future<List<UserModel>> filterUsers(UserFilterParams params) async {
    try {
      final queryParams = <String, dynamic>{};
      if (params.role != null) queryParams['role'] = params.role;
      if (params.status != null) queryParams['status'] = params.status!.displayName;
      if (params.userType != null) queryParams['user_type'] = params.userType!.displayName;
      if (params.projectId != null) queryParams['project_id'] = params.projectId;
      if (params.lastLoginStart != null) {
        queryParams['last_login_start'] = params.lastLoginStart!.toIso8601String();
      }
      if (params.lastLoginEnd != null) {
        queryParams['last_login_end'] = params.lastLoginEnd!.toIso8601String();
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');

      final response = await _apiService.get('organization/users/filter?$queryString');
      final usersJson = response['data'] as List<dynamic>? ?? response['users'] as List<dynamic>? ?? [];
      
      return usersJson
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('API Error in filter users: $e');
      throw Exception('Failed to filter users: $e');
    }
  }

  @override
  Future<Map<String, int>> getUserMetrics() async {
    try {
      final response = await _apiService.get('organization/users/metrics');
      final metrics = response['data'] as Map<String, dynamic>? ?? response;
      
      return {
        'total': metrics['total'] as int? ?? 0,
        'active': metrics['active'] as int? ?? 0,
        'invited': metrics['invited'] as int? ?? 0,
        'pending': metrics['pending'] as int? ?? 0,
        'inactive': metrics['inactive'] as int? ?? 0,
      };
    } catch (e) {
      print('API Error in getUserMetrics: $e');
      throw Exception('Failed to get user metrics: $e');
    }
  }
}

class UsersLocalDataSource implements UsersDataSource {
  List<UserModel>? _cachedUsers;

  @override
  Future<List<UserModel>> getUsers() async {
    if (_cachedUsers != null) {
      return _cachedUsers!;
    }
    throw Exception('No cached users available');
  }

  @override
  Future<UserModel> getUserById(String id) async {
    if (_cachedUsers != null) {
      return _cachedUsers!.firstWhere((u) => u.id == id);
    }
    throw Exception('No cached users available');
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    _cachedUsers ??= [];
    _cachedUsers!.add(user);
    return user;
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    if (_cachedUsers != null) {
      final index = _cachedUsers!.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _cachedUsers![index] = user;
      }
    }
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    _cachedUsers?.removeWhere((u) => u.id == id);
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    if (_cachedUsers != null) {
      return _cachedUsers!
          .where(
            (u) =>
                u.name.toLowerCase().contains(query.toLowerCase()) ||
                u.email.toLowerCase().contains(query.toLowerCase()) ||
                u.role.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    throw Exception('No cached users available');
  }

  @override
  Future<UserModel> inviteUser(InviteUserParams params) async {
    throw UnimplementedError();
  }

  @override
  Future<void> resendInvite(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> updateUserRoles(UpdateUserRoleParams params) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> assignUserToProjects(String userId, List<String> projectIds) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> removeUserFromProjects(String userId, List<String> projectIds) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> activateUser(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> deactivateUser(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<UserModel>> filterUsers(UserFilterParams params) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, int>> getUserMetrics() async {
    throw UnimplementedError();
  }

  void cacheUsers(List<UserModel> users) {
    _cachedUsers = users;
  }
}
