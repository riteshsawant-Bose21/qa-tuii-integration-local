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

  @override
  Future<DevicesModel> getFilteredDevices({
    String? searchQuery,
    String? status,
    String? project,
    String? model,
    String? type,
    String? category,
    String? projectId,
  }) async {
    final data = await datasource.getDeviceStats();

    List<Device> devices = List.from(data.devices);

    /// filter - project ID
    if (projectId != null) {
      devices =
          devices.where((d) => d.projectId == projectId).toList();
    }

    /// search
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();

      devices = devices.where((d) =>
          d.name.toLowerCase().contains(query) ||
          d.model.toLowerCase().contains(query)
      ).toList();
    }

    /// status
    if (status != null && status != 'All Status') {
      devices = devices.where((d) =>
          d.status.toLowerCase() == status.toLowerCase()
      ).toList();
    }

    /// Project
    if (project != null && project != 'All Projects') {
      devices = devices.where((d) => d.project == project).toList();
    }

    /// Model
    if (model != null && model != 'All Models') {
      devices = devices.where((d) => d.model == model).toList();
    }

    /// Type
    if (type != null && type != 'All Types') {
      devices = devices.where((d) => d.type == type).toList();
    }

    /// Sorting
    switch (category) {
      case 'Name':
        devices.sort((a, b) => a.name.compareTo(b.name));
        break;

      case 'Model':
        devices.sort((a, b) => a.model.compareTo(b.model));
        break;

      case 'Status':
        const order = {'healthy': 1, 'critical': 2, 'inactive': 3};

        devices.sort((a, b) {
          final aValue = order[a.status.toLowerCase()] ?? 99;
          final bValue = order[b.status.toLowerCase()] ?? 99;
          return aValue.compareTo(bValue);
        });
        break;

      case 'Last Seen':
        devices.sort((a, b) {
          final aTime = DateTime.tryParse(a.lastSeen) ?? DateTime(1970);
          final bTime = DateTime.tryParse(b.lastSeen) ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        break;
    }

    return data.copyWith(
      devices: devices,
      total: devices.length,
      healthy: devices.where((d) => d.status == 'healthy').length,
      critical: devices.where((d) => d.status == 'critical').length,
      inactive: devices.where((d) => d.status == 'inactive').length,
    );
  }
}