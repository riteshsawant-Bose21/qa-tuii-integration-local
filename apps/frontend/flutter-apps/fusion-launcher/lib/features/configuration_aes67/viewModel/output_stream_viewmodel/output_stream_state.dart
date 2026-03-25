part of 'output_stream_viewmodel.dart';

// ── Channel name model ────────────────────────────────────────────────────────

class OutputChannelConfig {
  final int channelNumber;
  final String name; // e.g. 'Channel 1', 'Channel 2'

  const OutputChannelConfig({
    required this.channelNumber,
    required this.name,
  });

  OutputChannelConfig copyWith({String? name}) => OutputChannelConfig(
    channelNumber: channelNumber,
    name: name ?? this.name,
  );
}

// ── Sealed states ─────────────────────────────────────────────────────────────

sealed class OutputStreamState {
  const OutputStreamState();
}

class OutputStreamInitial extends OutputStreamState {
  const OutputStreamInitial();
}

class OutputStreamLoading extends OutputStreamState {
  const OutputStreamLoading();
}

class OutputStreamError extends OutputStreamState {
  final String message;
  const OutputStreamError({required this.message});
}

class OutputStreamLoaded extends OutputStreamState {
  // ── Basic fields ─────────────────────────────────────────────────────
  final String name;
  final int channelCount;
  final List<OutputChannelConfig> channelConfigs;

  // ── Advanced section ─────────────────────────────────────────────────
  final bool isAdvancedExpanded;
  final String sessionId;
  final String ipAddress;
  final String bitDepth; // e.g. '24 bit'
  final String sampleRate; // e.g. '48 kHz'
  final String packetTime; // e.g. '1 ms'

  const OutputStreamLoaded({
    required this.name,
    required this.channelCount,
    required this.channelConfigs,
    required this.isAdvancedExpanded,
    required this.sessionId,
    required this.ipAddress,
    required this.bitDepth,
    required this.sampleRate,
    required this.packetTime,
  });

  OutputStreamLoaded copyWith({
    String? name,
    int? channelCount,
    List<OutputChannelConfig>? channelConfigs,
    bool? isAdvancedExpanded,
    String? sessionId,
    String? ipAddress,
    String? bitDepth,
    String? sampleRate,
    String? packetTime,
  }) => OutputStreamLoaded(
    name: name ?? this.name,
    channelCount: channelCount ?? this.channelCount,
    channelConfigs: channelConfigs ?? this.channelConfigs,
    isAdvancedExpanded: isAdvancedExpanded ?? this.isAdvancedExpanded,
    sessionId: sessionId ?? this.sessionId,
    ipAddress: ipAddress ?? this.ipAddress,
    bitDepth: bitDepth ?? this.bitDepth,
    sampleRate: sampleRate ?? this.sampleRate,
    packetTime: packetTime ?? this.packetTime,
  );
}
