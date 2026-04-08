/// Holds live system-monitor telemetry for a single device.
///
/// Populated from `fusion_system_monitor` meter packets whose blocks use
/// `block_name: system_info` and meter names `emmc`, `ram`, `temperature`,
/// `usb_storage`.
class DeviceSystemInfo {
  /// eMMC (disk) usage percentage (0–100).
  final double emmc;

  /// RAM usage percentage (0–100).
  final double ram;

  /// Device temperature in °C.
  final double temperature;

  /// USB storage usage percentage (0 when not present).
  final double usbStorage;

  /// Timestamp when this info was last updated.
  final DateTime updatedAt;

  const DeviceSystemInfo({
    this.emmc = 0,
    this.ram = 0,
    this.temperature = 0,
    this.usbStorage = 0,
    required this.updatedAt,
  });

  DeviceSystemInfo copyWith({
    double? emmc,
    double? ram,
    double? temperature,
    double? usbStorage,
    DateTime? updatedAt,
  }) {
    return DeviceSystemInfo(
      emmc: emmc ?? this.emmc,
      ram: ram ?? this.ram,
      temperature: temperature ?? this.temperature,
      usbStorage: usbStorage ?? this.usbStorage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether we have received meaningful data (at least one non-zero metric).
  bool get hasData => emmc > 0 || ram > 0 || temperature > 0 || usbStorage > 0;

  @override
  String toString() =>
      'DeviceSystemInfo(emmc: ${emmc.toStringAsFixed(1)}%, ram: ${ram.toStringAsFixed(1)}%, '
      'temp: ${temperature.toStringAsFixed(1)}°C, usb: ${usbStorage.toStringAsFixed(1)}%)';
}
