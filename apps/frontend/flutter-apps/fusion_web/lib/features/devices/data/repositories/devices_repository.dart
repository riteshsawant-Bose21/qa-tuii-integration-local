import '../models/devices_model.dart';

abstract class DevicesRepository {
  Future<DevicesModel> getDeviceStats();
}