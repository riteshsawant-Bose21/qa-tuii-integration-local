part of 'input_stream_viewmodel.dart';

enum Aes67AppMode { design, control }

class Aes67SessionEntry {
  final String id;
  final String sessionId;
  final int channels;
  final String ipVersion; // 'IPv4'
  final String ipAddress;
  final int port;
  final int bitDepth;
  final String sampleRate;
  final String packetTime;
  final bool isDanteDevice;

  const Aes67SessionEntry({
    required this.id,
    required this.sessionId,
    required this.channels,
    required this.ipVersion,
    required this.ipAddress,
    required this.port,
    required this.bitDepth,
    required this.sampleRate,
    required this.packetTime,
    required this.isDanteDevice,
  });

  Aes67SessionEntry copyWith({
    String? id,
    String? sessionId,
    int? channels,
    String? ipVersion,
    String? ipAddress,
    int? port,
    int? bitDepth,
    String? sampleRate,
    String? packetTime,
    bool? isDanteDevice,
  }) => Aes67SessionEntry(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    channels: channels ?? this.channels,
    ipVersion: ipVersion ?? this.ipVersion,
    ipAddress: ipAddress ?? this.ipAddress,
    port: port ?? this.port,
    bitDepth: bitDepth ?? this.bitDepth,
    sampleRate: sampleRate ?? this.sampleRate,
    packetTime: packetTime ?? this.packetTime,
    isDanteDevice: isDanteDevice ?? this.isDanteDevice,
  );
}

/// One per channel: the label (Left/Right/…) and the assigned output
class Aes67ChannelConfig {
  final int channelNumber;
  final String? label; // e.g. 'Left', 'Right', 'Center', …
  final String? assignedTo; // e.g. 'StageEX4ML1_1'

  const Aes67ChannelConfig({
    required this.channelNumber,
    this.label,
    this.assignedTo,
  });

  Aes67ChannelConfig copyWith({String? label, String? assignedTo}) => Aes67ChannelConfig(
    channelNumber: channelNumber,
    label: label ?? this.label,
    assignedTo: assignedTo ?? this.assignedTo,
  );
}

sealed class InputStreamState {
  const InputStreamState();
}

class InputStreamInitial extends InputStreamState {
  const InputStreamInitial();
}

class InputStreamLoading extends InputStreamState {
  const InputStreamLoading();
}

class InputStreamLoaded extends InputStreamState {
  final Aes67AppMode mode;

  // Top fields
  final String name;
  final String? assignedTo; // populated when a Dante-device session is selected

  // Channels
  final int channelCount;
  final List<Aes67ChannelConfig> channelConfigs;

  // Select Session section
  final bool isSessionSectionExpanded;
  final List<Aes67SessionEntry> sessions;
  final String? selectedSessionId; // id of the single selected session

  // Available "assigned to" options derived from sessions with isDanteDevice==true
  List<String> get danteAssignableOptions => sessions.where((Aes67SessionEntry s) => s.isDanteDevice).map((Aes67SessionEntry s) => s.sessionId).toList();

  const InputStreamLoaded({
    required this.mode,
    required this.name,
    this.assignedTo,
    required this.channelCount,
    required this.channelConfigs,
    required this.isSessionSectionExpanded,
    required this.sessions,
    this.selectedSessionId,
  });

  InputStreamLoaded copyWith({
    Aes67AppMode? mode,
    String? name,
    Object? assignedTo = _sentinel,
    int? channelCount,
    List<Aes67ChannelConfig>? channelConfigs,
    bool? isSessionSectionExpanded,
    List<Aes67SessionEntry>? sessions,
    Object? selectedSessionId = _sentinel,
  }) {
    return InputStreamLoaded(
      mode: mode ?? this.mode,
      name: name ?? this.name,
      assignedTo: assignedTo == _sentinel ? this.assignedTo : assignedTo as String?,
      channelCount: channelCount ?? this.channelCount,
      channelConfigs: channelConfigs ?? this.channelConfigs,
      isSessionSectionExpanded: isSessionSectionExpanded ?? this.isSessionSectionExpanded,
      sessions: sessions ?? this.sessions,
      selectedSessionId: selectedSessionId == _sentinel ? this.selectedSessionId : selectedSessionId as String?,
    );
  }
}

const Object _sentinel = Object();

class ConfigAes67DialogError extends InputStreamState {
  final String message;
  const ConfigAes67DialogError({required this.message});
}
