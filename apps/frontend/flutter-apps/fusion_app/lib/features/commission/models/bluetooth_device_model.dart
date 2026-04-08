class BluetoothDeviceModel {
  final String name;
  final String? ipAddress;
  final bool selected;

  const BluetoothDeviceModel({
    required this.name,
     this.ipAddress,
    this.selected = false,
  });

  BluetoothDeviceModel copyWith({bool? selected}) {
    return BluetoothDeviceModel(
      name: name,
      ipAddress: ipAddress,
      selected: selected ?? this.selected,
    );
  }
}
