abstract class DeviceListingState<T> {}

class DeviceListingIdleState<T> extends DeviceListingState<T> {
  final List<T> devices;
  DeviceListingIdleState({required this.devices});
}

class DeviceSearchingState<T> extends DeviceListingState<T> {
  final String query;
  final List<T> devices;
  DeviceSearchingState({required this.query, required this.devices});
}

extension DeviceListingStateExtension<T> on DeviceListingState<T> {
  DeviceSearchingState<T> search(String query, List<T> devices) => DeviceSearchingState<T>(query: query, devices: devices);
  DeviceListingIdleState<T> idle(List<T> devices) => DeviceListingIdleState<T>(devices: devices);

  List<T> get devices => switch (this) {
    DeviceListingIdleState<T>(devices: final List<T> devices) => devices,
    DeviceSearchingState<T>(devices: final List<T> devices) => devices,
    _ => <T>[],
  };
}
