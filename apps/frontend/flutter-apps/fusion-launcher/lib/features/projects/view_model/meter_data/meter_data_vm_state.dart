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

  /// Convenience: look up system info for a given device ID.
  /// Returns `null` if no telemetry has been received for this device yet.
  DeviceSystemInfo? systemInfoFor(String deviceId) => deviceSystemInfo[deviceId];

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
