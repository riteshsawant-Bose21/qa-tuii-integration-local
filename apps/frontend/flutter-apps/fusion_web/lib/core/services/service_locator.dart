import 'package:fusion_web/core/services/api_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  ApiService? _apiService;

  ApiService get apiService {
    _apiService ??= ApiService();
    return _apiService!;
  }

  void reset() {
    _apiService?.dispose();
    _apiService = null;
  }

  void dispose() {
    _apiService?.dispose();
  }
}
