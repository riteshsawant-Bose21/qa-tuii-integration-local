part of 'meter_data_view_model.dart';

class MeterDataState {
  /// Live packet map — populated only while connected.
  final Map<String, MeterPacket> packets;

  /// True while the telemetry subscription is active.
  final bool isConnected;

  /// Non-null when telemetry is intentionally inactive.
  final MeterInactiveReason? inactiveReason;

  /// for quick access to block and its value
  final Map<String, MeterBlock>? meterValues;

  /// Per-device system monitor info (temp, CPU/RAM, disk/eMMC).
  /// Keyed by the `device_id` from the meter packet (e.g., "FUSIONDSP419486553").
  final Map<String, DeviceSystemInfo> deviceSystemInfo;

  const MeterDataState({
    this.packets = const <String, MeterPacket>{},
    this.isConnected = false,
    this.inactiveReason = MeterInactiveReason.notStarted,
    this.meterValues,
    this.deviceSystemInfo = const <String, DeviceSystemInfo>{},
  });

  bool get hasData => packets.isNotEmpty;

  /// Look up system info for a hardware component by its project-level ID.
  ///
  /// Resolution order:
  /// 1. Direct match against `deviceSystemInfo` keys (works after device mapping
  ///    when the physical device ID has been set to the project component ID).
  /// 2. Match via `fusionDevices` list in the project — each [FusionDevice.id]
  ///    is the physical network device ID (e.g., "FUSIONDSP419486553").
  ///    If any FusionDsp hardware component's project ID matches [deviceId],
  ///    its corresponding FusionDevice network ID is used to look up system info.
  /// 3. Fallback: if there is exactly one system-info entry, return it.
  ///    This handles single-device setups where the ID mapping hasn't occurred.
  DeviceSystemInfo? systemInfoFor(String deviceId) {
    // 1. Direct key match.
    final DeviceSystemInfo? direct = deviceSystemInfo[deviceId];
    if (direct != null) return direct;

    // 2. Try matching via the FusionDevice list (network-device-id → project-id mapping).
    try {
      final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
      // fusionDevices returns FusionDsp objects whose IDs are network device IDs
      // after the device assignment flow.
      for (final FusionDsp fd in vm.fusionDevices) {
        if (fd.id == deviceId) {
          // The FusionDsp project ID matches — the network device ID should be
          // in our deviceSystemInfo map.
          // After device mapping, fd.id IS the network device ID, so it should
          // have matched in step 1. If we're here, the IDs don't match.
          continue;
        }
        // Check if the network device ID (the key in deviceSystemInfo) corresponds
        // to this FusionDsp.
        final DeviceSystemInfo? info = deviceSystemInfo[fd.id];
        if (info != null) {
          // We found system info for this FusionDsp. If there's only one DSP
          // in the project, this is likely the correct match.
          return info;
        }
      }
    } catch (_) {
      // ProjectViewModel might not be available yet.
    }

    // 3. Fallback: single system-info entry → return it for any device.
    if (deviceSystemInfo.length == 1) {
      return deviceSystemInfo.values.first;
    }

    return null;
  }

  MeterDataState copyWith({
    Map<String, MeterPacket>? packets,
    bool? isConnected,
    MeterInactiveReason? inactiveReason,
    bool clearInactiveReason = false,
    Map<String, MeterBlock>? meterValues,
    Map<String, DeviceSystemInfo>? deviceSystemInfo,
  }) {
    return MeterDataState(
      packets: packets ?? this.packets,
      isConnected: isConnected ?? this.isConnected,
      inactiveReason: clearInactiveReason ? null : (inactiveReason ?? this.inactiveReason),
      meterValues: meterValues ?? this.meterValues,
      deviceSystemInfo: deviceSystemInfo ?? this.deviceSystemInfo,
    );
  }
}
