import 'package:flutter/material.dart';
import 'package:fusion_web/features/auth/domain/entities/user_entity.dart';
import 'package:fusion_web/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fusion_web/core/services/service_locator.dart';

class AuthViewModel extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final IsLoggedInUseCase isLoggedInUseCase;
  final AuthRepositoryImpl? _authRepository;

  AuthViewModel({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.isLoggedInUseCase,
    AuthRepositoryImpl? authRepository,
  }) : _authRepository = authRepository;

  UserEntity? _currentUser;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;

  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;

  void initialize() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      _isLoggedIn = await isLoggedInUseCase();
      if (_isLoggedIn) {
        await _initializeApiToken();
        _currentUser = await getCurrentUserUseCase();
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _initializeApiToken() async {
    try {
      if (_authRepository != null) {
        final token = await _authRepository.getIdToken();
        if (token != null) {
          ServiceLocator().apiService.setBearerToken(token);
        }
      }
    } catch (e) {
      print('Failed to initialize API token: $e');
    }
  }

  Future<void> login() async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await loginUseCase();
      _isLoggedIn = _currentUser != null;

      if (_isLoggedIn) {
        await _initializeApiToken();
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await logoutUseCase();
      ServiceLocator().apiService.clearToken();
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
