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
  DeviceFormData({
    this.selectedDevice,
    this.selectedLocation,
  });

  DeviceFormData<T> copyWith({
    T? selectedDevice,
    String? selectedLocation,
  }) {
    return DeviceFormData<T>(
      selectedDevice: selectedDevice ?? this.selectedDevice,
      selectedLocation: selectedLocation ?? this.selectedLocation,
    );
  }

  @override
  String toString() => 'DeviceFormState(selectedDevice: $selectedDevice, selectedLocation: $selectedLocation)';

  @override
  bool operator ==(covariant DeviceFormData<T> other) {
    if (identical(this, other)) return true;

    return other.selectedDevice == selectedDevice && other.selectedLocation == selectedLocation;
  }

  @override
  int get hashCode => selectedDevice.hashCode ^ selectedLocation.hashCode;
}
