part of 'config_aes67_viewmodel.dart';

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
  final List<Aes67Config> inputStreams;
  final List<Aes67Config> outputStreams;

  const ConfigAes67Loaded({
    required this.clockLeader,
    required this.globalStatus,
    required this.inputStreams,
    required this.outputStreams,
  });

  ConfigAes67Loaded copyWith({
    String? clockLeader,
    bool? globalStatus,
    List<Aes67Config>? inputStreams,
    List<Aes67Config>? outputStreams,
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
