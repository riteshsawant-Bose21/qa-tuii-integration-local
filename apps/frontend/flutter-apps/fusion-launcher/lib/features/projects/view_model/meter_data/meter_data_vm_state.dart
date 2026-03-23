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

  // Ensure it's in your constructor and copyWith...

  const MeterDataState({
    this.packets = const <String, MeterPacket>{},
    this.isConnected = false,
    this.inactiveReason = MeterInactiveReason.notStarted,
    this.meterValues,
  });

  bool get hasData => packets.isNotEmpty;

  MeterDataState copyWith({
    Map<String, MeterPacket>? packets,
    bool? isConnected,
    MeterInactiveReason? inactiveReason,
    bool clearInactiveReason = false,
    Map<String, MeterBlock>? meterValues,
  }) {
    return MeterDataState(
      packets: packets ?? this.packets,
      isConnected: isConnected ?? this.isConnected,
      inactiveReason: clearInactiveReason ? null : (inactiveReason ?? this.inactiveReason),
      meterValues: meterValues ?? this.meterValues,
    );
  }
}
