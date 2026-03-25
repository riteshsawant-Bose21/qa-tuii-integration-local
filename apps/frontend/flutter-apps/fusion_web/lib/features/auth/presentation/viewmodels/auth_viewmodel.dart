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
    print('🔍 AuthViewModel: Checking auth status...');
    try {
      _isLoggedIn = await isLoggedInUseCase();
      print('🔍 AuthViewModel: isLoggedIn = $_isLoggedIn');

      if (_isLoggedIn) {
        await _initializeApiToken();
        _currentUser = await getCurrentUserUseCase();
        print('🔍 AuthViewModel: Current user loaded: ${_currentUser?.email}');
      }
      notifyListeners();
    } catch (e) {
      print('⚠️ AuthViewModel: Error checking auth status: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _initializeApiToken() async {
    print('🔐 AuthViewModel: Initializing API token...');
    try {
      if (_authRepository != null) {
        final token = await _authRepository.getIdToken();
        if (token != null) {
          ServiceLocator().apiService.setBearerToken(token);
          print('✅ AuthViewModel: API token set successfully');
        } else {
          print('⚠️ AuthViewModel: No token received from auth repository');
        }
      } else {
        print('⚠️ AuthViewModel: Auth repository is null');
      }
    } catch (e) {
      print('❌ AuthViewModel: Failed to initialize API token: $e');
    }
  }

  Future<void> login() async {
    _setLoading(true);
    _clearError();

    try {
      // First check if user is already logged in to avoid unnecessary redirects
      final isAlreadyLoggedIn = await isLoggedInUseCase();
      if (isAlreadyLoggedIn) {
        print('User is already logged in, skipping Auth0 redirect');
        _currentUser = await getCurrentUserUseCase();
        _isLoggedIn = true;
        await _initializeApiToken();
        notifyListeners();
        return;
      }

      _currentUser = await loginUseCase();
      _isLoggedIn = _currentUser != null;

      if (_isLoggedIn) {
        await _initializeApiToken();
      }

      notifyListeners();
    } catch (e) {
      print('Login error: $e');
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
