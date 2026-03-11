import 'package:fusion_web/features/devices/data/datasources/device_datasource.dart';
import 'package:fusion_web/features/devices/data/models/devices_model.dart';
import 'package:fusion_web/features/devices/data/repositories/devices_repository.dart';

class DevicesRepositoryImpl implements DevicesRepository {

  final DeviceDatasource datasource;

  DevicesRepositoryImpl(this.datasource);

  @override
  Future<DevicesModel> getDeviceStats() {
    return datasource.getDeviceStats();
  }
}