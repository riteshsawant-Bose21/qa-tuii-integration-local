part of 'add_output_device_vm.dart';

class AddOutputDeviceVmState extends Equatable {
  final OutputDeviceType? outputType;
  final AudioChannel? audioChannel;
  final OutputDeviceConnectionType? connection;

  const AddOutputDeviceVmState({
    this.outputType,
    this.audioChannel,
    this.connection,
  });

  factory AddOutputDeviceVmState.initial() => const AddOutputDeviceVmState();

  @override
  List<Object?> get props => <Object?>[outputType, audioChannel, connection];

  AddOutputDeviceVmState copyWith({
    ValueGetter<OutputDeviceType?>? outputType,
    ValueGetter<AudioChannel?>? audioChannel,
    ValueGetter<OutputDeviceConnectionType?>? connection,
  }) {
    return AddOutputDeviceVmState(
      outputType: outputType != null ? outputType() : this.outputType,
      audioChannel: audioChannel != null ? audioChannel() : this.audioChannel,
      connection: connection != null ? connection() : this.connection,
    );
  }
}

enum OutputDeviceConnectionType {
  analogOutput,
  digitalOutput,
  aes67,
  bluetooth;

  String get displayName => switch (this) {
    OutputDeviceConnectionType.analogOutput => 'Analog Output',
    OutputDeviceConnectionType.digitalOutput => 'Digital Output',
    OutputDeviceConnectionType.aes67 => 'AES67',
    OutputDeviceConnectionType.bluetooth => 'Bluetooth',
  };
}

enum OutputDeviceType {
  mediaRecorder,
  amplifier,
  speaker,
  mixer;

  String get displayName => switch (this) {
    OutputDeviceType.mediaRecorder => 'Media Recorder',
    OutputDeviceType.amplifier => 'Amplifier',
    OutputDeviceType.speaker => 'Speaker',
    OutputDeviceType.mixer => 'Mixer',
  };
}

enum AudioChannel {
  mono,
  stereo;

  String get displayName => switch (this) {
    AudioChannel.mono => 'Mono',
    AudioChannel.stereo => 'Stereo',
  };
}
