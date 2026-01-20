import 'package:fusion_web/features/users/data/models/user_model.dart';

abstract class UsersDataSource {
  Future<List<UserModel>> getUsers();
  Future<UserModel> getUserById(String id);
  Future<UserModel> createUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String id);
  Future<List<UserModel>> searchUsers(String query);
}

class UsersRemoteDataSource implements UsersDataSource {
  @override
  Future<List<UserModel>> getUsers() async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel.mockUsers();
  }

  @override
  Future<UserModel> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final users = UserModel.mockUsers();
    return users.firstWhere((u) => u.id == id);
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return user;
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
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
