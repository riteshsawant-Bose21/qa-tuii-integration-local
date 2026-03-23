import '../models/devices_model.dart';

abstract class DevicesRepository {
  
  Future<DevicesModel> getDeviceStats();

  Future<DevicesModel> getFilteredDevices({
  String? searchQuery,
  String? status,
  String? project,
  String? model,
  String? type,
  String? category,
  String? projectId,
});
}