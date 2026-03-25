// ignore_for_file: public_member_api_docs, sort_constructors_first
class DeviceFormState<T> {
  final bool isComplete;
  final T formData;
  DeviceFormState({
    this.isComplete = false,
    required this.formData,
  });

  DeviceFormState<T> copyWith({
    bool? isComplete,
    T? formData,
  }) {
    return DeviceFormState<T>(
      isComplete: isComplete ?? this.isComplete,
      formData: formData ?? this.formData,
    );
  }
}

class DeviceFormData<T> {
  final T? selectedDevice;
  final String? selectedLocation;
  final String? floorId;
  DeviceFormData({
    this.selectedDevice,
    this.selectedLocation,
    this.floorId,
  });

  DeviceFormData<T> copyWith({
    T? selectedDevice,
    String? selectedLocation,
    String? floorId,
  }) {
    return DeviceFormData<T>(
      selectedDevice: selectedDevice ?? this.selectedDevice,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      floorId: floorId ?? this.floorId,
    );
  }

  @override
  String toString() => 'DeviceFormData(selectedDevice: $selectedDevice, selectedLocation: $selectedLocation, floorId: $floorId)';

  @override
  bool operator ==(covariant DeviceFormData<T> other) {
    if (identical(this, other)) return true;

    return other.selectedDevice == selectedDevice && other.selectedLocation == selectedLocation && other.floorId == floorId;
  }

  @override
  int get hashCode => selectedDevice.hashCode ^ selectedLocation.hashCode ^ floorId.hashCode;
}
