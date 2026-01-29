import 'package:fusion_web/features/users/data/models/user_model.dart';
import 'package:fusion_web/core/services/api_service.dart';

abstract class UsersDataSource {
  Future<List<UserModel>> getUsers();
  Future<UserModel> getUserById(String id);
  Future<UserModel> createUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String id);
  Future<List<UserModel>> searchUsers(String query);
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

  void cacheUsers(List<UserModel> users) {
    _cachedUsers = users;
  }
}
