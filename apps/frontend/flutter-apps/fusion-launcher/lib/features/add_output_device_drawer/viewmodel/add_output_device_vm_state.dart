part of 'add_output_device_vm.dart';

class AddOutputDeviceVmState extends Equatable {
  final String? outputDeviceName;
  final OutputDeviceType? outputType;
  final AudioChannel? audioChannel;
  final OutputDeviceConnectionType? connection;
  final Aes67Config? selectedStream;

  // For Mono: selectedMonoChannel;
  final int? selectedMonoChannel;

  // For Stereo: selectedLeftChannel and selectedRightChannel
  final int? selectedLeftChannel;
  final int? selectedRightChannel;

  const AddOutputDeviceVmState({
    this.outputDeviceName,
    this.outputType,
    this.audioChannel,
    this.connection,
    this.selectedStream,
    this.selectedMonoChannel = 1,
    this.selectedLeftChannel = 1,
    this.selectedRightChannel = 2,
  });

  factory AddOutputDeviceVmState.initial() => const AddOutputDeviceVmState();

  @override
  List<Object?> get props => <Object?>[
    outputDeviceName,
    outputType,
    audioChannel,
    connection,
    selectedStream,
    selectedMonoChannel,
    selectedLeftChannel,
    selectedRightChannel,
  ];

  AddOutputDeviceVmState copyWith({
    ValueGetter<String?>? outputDeviceName,
    ValueGetter<OutputDeviceType?>? outputType,
    ValueGetter<AudioChannel?>? audioChannel,
    ValueGetter<OutputDeviceConnectionType?>? connection,
    ValueGetter<Aes67Config?>? selectedStream,
    ValueGetter<int?>? selectedMonoChannel,
    ValueGetter<int?>? selectedLeftChannel,
    ValueGetter<int?>? selectedRightChannel,
  }) {
    return AddOutputDeviceVmState(
      outputDeviceName: outputDeviceName != null ? outputDeviceName() : this.outputDeviceName,
      outputType: outputType != null ? outputType() : this.outputType,
      audioChannel: audioChannel != null ? audioChannel() : this.audioChannel,
      connection: connection != null ? connection() : this.connection,
      selectedStream: selectedStream != null ? selectedStream() : this.selectedStream,
      selectedMonoChannel: selectedMonoChannel != null ? selectedMonoChannel() : this.selectedMonoChannel,
      selectedLeftChannel: selectedLeftChannel != null ? selectedLeftChannel() : this.selectedLeftChannel,
      selectedRightChannel: selectedRightChannel != null ? selectedRightChannel() : this.selectedRightChannel,
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
