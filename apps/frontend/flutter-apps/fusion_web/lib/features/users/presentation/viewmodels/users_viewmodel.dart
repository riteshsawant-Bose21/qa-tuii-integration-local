import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/core/usecases/usecase.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';
import 'package:fusion_web/features/users/domain/usecases/users_usecases.dart';

class UsersViewModel extends BaseViewModel {
  final GetUsersUseCase getUsersUseCase;
  final GetUserByIdUseCase getUserByIdUseCase;
  final CreateUserUseCase createUserUseCase;
  final UpdateUserUseCase updateUserUseCase;
  final DeleteUserUseCase deleteUserUseCase;
  final SearchUsersUseCase searchUsersUseCase;

  List<UserEntity> _users = [];
  List<UserEntity> _filteredUsers = [];
  UserEntity? _selectedUser;
  String _searchQuery = '';

  UsersViewModel({
    required this.getUsersUseCase,
    required this.getUserByIdUseCase,
    required this.createUserUseCase,
    required this.updateUserUseCase,
    required this.deleteUserUseCase,
    required this.searchUsersUseCase,
  });

  List<UserEntity> get users {
    if (_filteredUsers.isNotEmpty) {
      return _filteredUsers;
    }
    return _users;
  }

  UserEntity? get selectedUser => _selectedUser;
  String get searchQuery => _searchQuery;

  Future<void> loadUsers() async {
    try {
      setLoading();
      final users = await getUsersUseCase(const NoParams());
      _users = users;
      _filteredUsers = [];
      setLoaded(users);
    } catch (e) {
      _users = [];
      _filteredUsers = [];
      setError('Failed to load users: ${e.toString()}');
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
                u.role.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
      notifyListeners();
    }
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

  Future<void> updateUser(UserEntity user) async {
    try {
      setLoading();
      await updateUserUseCase(user);
      await loadUsers();
    } catch (e) {
      setError('Failed to update user: ${e.toString()}');
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
