part of 'config_aes67_viewmodel.dart';

class Aes67Stream {
  final String id;
  final String name;
  final String device;
  final String streamOrAdvertisement;
  final String addressPort;
  final int channels;
  final String bitDepth;
  final String packetTime;
  final bool isEnabled;

  const Aes67Stream({
    required this.id,
    required this.name,
    required this.device,
    required this.streamOrAdvertisement,
    required this.addressPort,
    required this.channels,
    required this.bitDepth,
    required this.packetTime,
    required this.isEnabled,
  });

  Aes67Stream copyWith({
    String? id,
    String? name,
    String? device,
    String? streamOrAdvertisement,
    String? addressPort,
    int? channels,
    String? bitDepth,
    String? packetTime,
    bool? isEnabled,
  }) {
    return Aes67Stream(
      id: id ?? this.id,
      name: name ?? this.name,
      device: device ?? this.device,
      streamOrAdvertisement: streamOrAdvertisement ?? this.streamOrAdvertisement,
      addressPort: addressPort ?? this.addressPort,
      channels: channels ?? this.channels,
      bitDepth: bitDepth ?? this.bitDepth,
      packetTime: packetTime ?? this.packetTime,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

sealed class ConfigAes67State {
  const ConfigAes67State();
}

class ConfigAes67Initial extends ConfigAes67State {
  const ConfigAes67Initial();
}

class ConfigAes67Loading extends ConfigAes67State {
  const ConfigAes67Loading();
}

class ConfigAes67Loaded extends ConfigAes67State {
  final String clockLeader;
  final bool globalStatus;
  final List<Aes67Stream> inputStreams;
  final List<Aes67Stream> outputStreams;

  const ConfigAes67Loaded({
    required this.clockLeader,
    required this.globalStatus,
    required this.inputStreams,
    required this.outputStreams,
  });

  ConfigAes67Loaded copyWith({
    String? clockLeader,
    bool? globalStatus,
    List<Aes67Stream>? inputStreams,
    List<Aes67Stream>? outputStreams,
  }) {
    return ConfigAes67Loaded(
      clockLeader: clockLeader ?? this.clockLeader,
      globalStatus: globalStatus ?? this.globalStatus,
      inputStreams: inputStreams ?? this.inputStreams,
      outputStreams: outputStreams ?? this.outputStreams,
    );
  }
}

class ConfigAes67Error extends ConfigAes67State {
  final String message;
  const ConfigAes67Error({required this.message});
}
