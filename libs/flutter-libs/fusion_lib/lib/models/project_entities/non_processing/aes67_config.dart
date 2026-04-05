import 'package:uuid/uuid.dart';

/// Enum representing the type of AES67 stream
enum Aes67StreamType {
  input,
  output,
}

extension Aes67StreamTypeExtension on Aes67StreamType {
  String get displayName {
    switch (this) {
      case Aes67StreamType.input:
        return 'Input Stream';
      case Aes67StreamType.output:
        return 'Output Stream';
    }
  }
}

/// Channel configuration for AES67 streams
class Aes67ChannelConfig {
  final int channelNumber;
  final String? label;
  final String? assignedTo;

  const Aes67ChannelConfig({
    required this.channelNumber,
    this.label,
    this.assignedTo,
  });

  Aes67ChannelConfig copyWith({
    int? channelNumber,
    String? label,
    String? assignedTo,
    bool clearLabel = false,
    bool clearAssignedTo = false,
  }) {
    return Aes67ChannelConfig(
      channelNumber: channelNumber ?? this.channelNumber,
      label: clearLabel ? null : (label ?? this.label),
      assignedTo: clearAssignedTo ? null : (assignedTo ?? this.assignedTo),
    );
  }

  factory Aes67ChannelConfig.fromJson(Map<String, dynamic> json) {
    return Aes67ChannelConfig(
      channelNumber: json['channelNumber'] as int,
      label: json['label'] as String?,
      assignedTo: json['assignedTo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channelNumber': channelNumber,
      'label': label,
      'assignedTo': assignedTo,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Aes67ChannelConfig && other.channelNumber == channelNumber && other.label == label && other.assignedTo == assignedTo;
  }

  @override
  int get hashCode => Object.hash(channelNumber, label, assignedTo);
}

/// Session entry for AES67 input streams
class Aes67SessionEntry {
  final String id;
  final String sessionId;
  final int channels;
  final String ipVersion;
  final String ipAddress;
  final int port;
  final int bitDepth;
  final String sampleRate;
  final String packetTime;
  final bool isDanteDevice;
  final List<String> channelLabels; // Channel labels from API (e.g., ["Ch1", "Ch2", ...])

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
    this.isDanteDevice = false,
    this.channelLabels = const <String>[],
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
    List<String>? channelLabels,
  }) {
    return Aes67SessionEntry(
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
      channelLabels: channelLabels ?? this.channelLabels,
    );
  }

  factory Aes67SessionEntry.fromJson(Map<String, dynamic> json) {
    final int channelCount = json['channels'] as int;
    final List<String> labels =
        (json['channelLabels'] as List<dynamic>?)?.map((dynamic e) => e as String).toList() ?? List<String>.generate(channelCount, (int i) => 'Ch${i + 1}');
    return Aes67SessionEntry(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      channels: channelCount,
      ipVersion: json['ipVersion'] as String? ?? 'IPv4',
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int,
      bitDepth: json['bitDepth'] as int,
      sampleRate: json['sampleRate'] as String,
      packetTime: json['packetTime'] as String,
      isDanteDevice: json['isDanteDevice'] as bool? ?? false,
      channelLabels: labels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'channels': channels,
      'ipVersion': ipVersion,
      'ipAddress': ipAddress,
      'port': port,
      'bitDepth': bitDepth,
      'sampleRate': sampleRate,
      'packetTime': packetTime,
      'isDanteDevice': isDanteDevice,
      'channelLabels': channelLabels,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Aes67SessionEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model representing an AES67 stream configuration
class Aes67Config {
  final String id;
  final String name;
  final String device;
  final Aes67StreamType streamType;
  final String streamOrAdvertisement;
  final String ipAddress;
  final int? port;
  final int channels;
  final String bitDepth;
  final String sampleRate;
  final String packetTime;
  final bool isEnabled;
  final List<Aes67ChannelConfig> channelConfigs;
  final List<Aes67SessionEntry> sessions;
  final String? selectedSessionId;
  final String? assignedTo;

  Aes67Config({
    String? id,
    required this.name,
    this.device = '-',
    required this.streamType,
    this.streamOrAdvertisement = '-',
    this.ipAddress = '-',
    this.port,
    this.channels = 2,
    this.bitDepth = '-',
    this.sampleRate = '-',
    this.packetTime = '-',
    this.isEnabled = true,
    List<Aes67ChannelConfig>? channelConfigs,
    List<Aes67SessionEntry>? sessions,
    this.selectedSessionId,
    this.assignedTo,
  }) : id = id ?? const Uuid().v4(),
       channelConfigs = channelConfigs ?? buildDefaultChannels(channels),
       sessions = sessions ?? <Aes67SessionEntry>[];

  static List<Aes67ChannelConfig> buildDefaultChannels(int count) {
    const Map<int, List<String>> channelLabels = <int, List<String>>{
      1: <String>['Mono'],
      2: <String>['Left', 'Right'],
      3: <String>['Left', 'Right', 'Center'],
      4: <String>['Left', 'Right', 'Center', 'LFE'],
      5: <String>['Left', 'Right', 'Center', 'LFE', 'Surround'],
      6: <String>['Left', 'Right', 'Center', 'LFE', 'Ls', 'Rs'],
      7: <String>['Left', 'Right', 'Center', 'LFE', 'Ls', 'Rs', 'Cs'],
      8: <String>['Left', 'Right', 'Center', 'LFE', 'Lss', 'Rss', 'Lrs', 'Rrs'],
    };
    final List<String> labels = channelLabels[count] ?? List<String>.generate(count, (int i) => 'Ch ${i + 1}');
    return List<Aes67ChannelConfig>.generate(
      count,
      (int i) => Aes67ChannelConfig(
        channelNumber: i + 1,
        label: labels[i],
        assignedTo: null,
      ),
    );
  }

  factory Aes67Config.fromJson(Map<String, dynamic> json) {
    final int channels = json['channels'] as int? ?? 2;
    return Aes67Config(
      id: json['id'] as String,
      name: json['name'] as String,
      device: json['device'] as String? ?? '-',
      streamType: Aes67StreamType.values.firstWhere(
        (e) => e.name == json['streamType'],
        orElse: () => Aes67StreamType.input,
      ),
      streamOrAdvertisement: json['streamOrAdvertisement'] as String? ?? '-',
      ipAddress: json['ipAddress'] as String? ?? '-',
      port: json['port'] as int?,
      channels: channels,
      bitDepth: json['bitDepth'] as String? ?? '-',
      sampleRate: json['sampleRate'] as String? ?? '-',
      packetTime: json['packetTime'] as String? ?? '-',
      isEnabled: json['isEnabled'] as bool? ?? true,
      channelConfigs:
          (json['channelConfigs'] as List<dynamic>?)?.map((e) => Aes67ChannelConfig.fromJson(e as Map<String, dynamic>)).toList() ??
          buildDefaultChannels(channels),
      sessions: (json['sessions'] as List<dynamic>?)?.map((e) => Aes67SessionEntry.fromJson(e as Map<String, dynamic>)).toList() ?? <Aes67SessionEntry>[],
      selectedSessionId: json['selectedSessionId'] as String?,
      assignedTo: json['assignedTo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'device': device,
      'streamType': streamType.name,
      'streamOrAdvertisement': streamOrAdvertisement,
      'ipAddress': ipAddress,
      'port': port,
      'channels': channels,
      'bitDepth': bitDepth,
      'sampleRate': sampleRate,
      'packetTime': packetTime,
      'isEnabled': isEnabled,
      'channelConfigs': channelConfigs.map((c) => c.toJson()).toList(),
      'selectedSessionId': selectedSessionId,
    };
  }

  Aes67Config copyWith({
    String? id,
    String? name,
    String? device,
    Aes67StreamType? streamType,
    String? streamOrAdvertisement,
    String? ipAddress,
    int? port,
    int? channels,
    String? bitDepth,
    String? sampleRate,
    String? packetTime,
    bool? isEnabled,
    List<Aes67ChannelConfig>? channelConfigs,
    List<Aes67SessionEntry>? sessions,
    String? selectedSessionId,
    String? assignedTo,
    bool clearSelectedSessionId = false,
    bool clearAssignedTo = false,
  }) {
    return Aes67Config(
      id: id ?? this.id,
      name: name ?? this.name,
      device: device ?? this.device,
      streamType: streamType ?? this.streamType,
      streamOrAdvertisement: streamOrAdvertisement ?? this.streamOrAdvertisement,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      channels: channels ?? this.channels,
      bitDepth: bitDepth ?? this.bitDepth,
      sampleRate: sampleRate ?? this.sampleRate,
      packetTime: packetTime ?? this.packetTime,
      isEnabled: isEnabled ?? this.isEnabled,
      channelConfigs: channelConfigs ?? this.channelConfigs,
      sessions: sessions ?? this.sessions,
      selectedSessionId: clearSelectedSessionId ? null : (selectedSessionId ?? this.selectedSessionId),
      assignedTo: clearAssignedTo ? null : (assignedTo ?? this.assignedTo),
    );
  }

  /// Get list of Dante assignable options from sessions
  List<String> get danteAssignableOptions => sessions.where((s) => s.isDanteDevice).map((s) => s.sessionId).toList();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Aes67Config && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Aes67Config(id: $id, name: $name, device: $device, streamType: $streamType, channels: $channels, isEnabled: $isEnabled)';
  }
}
