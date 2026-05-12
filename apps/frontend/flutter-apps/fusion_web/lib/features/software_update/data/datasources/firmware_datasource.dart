import 'package:fusion_web/core/services/api_service.dart';
import 'package:fusion_web/features/software_update/data/models/firmware_bundle.dart';

class FirmwareDataSource {
  final ApiService _apiService;

  FirmwareDataSource({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<FirmwareBundlesResponse> getBundles({
    int page = 1,
    int limit = 15,
  }) async {
    final response = await _apiService.get(
      '/firmware/bundles?page=$page&limit=$limit',
    );
    return FirmwareBundlesResponse.fromJson(response);
  }

  Future<void> approveFirmware(String bundleId) async {
    await _apiService.put(
      'firmware/bundles/$bundleId/approve?action=approve',
      {},
    );
  }

  Future<void> revokeFirmware(String bundleId) async {
    await _apiService.put(
      'firmware/bundles/$bundleId/approve?action=revoke',
      {},
    );
  }
}
