part of 'add_output_device_vm.dart';

class AddOutputDeviceVmState extends Equatable {
  final String? zoneId;
  final String? outputDeviceName;
  final int? outputProductId;
  final AudioChannel audioChannel;
  final OutputConnectionType? connectionType;
  final Aes67Config? selectedStream;

  // For Mono: selectedMonoChannel;
  final int? selectedMonoChannel;

  // For Stereo: selectedLeftChannel and selectedRightChannel
  final int? selectedLeftChannel;
  final int? selectedRightChannel;

  const AddOutputDeviceVmState({
    this.zoneId,
    this.outputDeviceName,
    this.outputProductId,
    this.audioChannel = AudioChannel.mono,
    this.connectionType,
    this.selectedStream,
    this.selectedMonoChannel = 1,
    this.selectedLeftChannel = 1,
    this.selectedRightChannel = 2,
  });

  factory AddOutputDeviceVmState.initial() => const AddOutputDeviceVmState();

  @override
  List<Object?> get props => <Object?>[
    zoneId,
    outputDeviceName,
    outputProductId,
    audioChannel,
    connectionType,
    selectedStream,
    selectedMonoChannel,
    selectedLeftChannel,
    selectedRightChannel,
  ];

  AddOutputDeviceVmState copyWith({
    ValueGetter<String?>? zoneId,
    ValueGetter<String?>? outputDeviceName,
    ValueGetter<int?>? outputProductId,
    ValueGetter<AudioChannel>? audioChannel,
    ValueGetter<OutputConnectionType?>? connectionType,
    ValueGetter<Aes67Config?>? selectedStream,
    ValueGetter<int?>? selectedMonoChannel,
    ValueGetter<int?>? selectedLeftChannel,
    ValueGetter<int?>? selectedRightChannel,
  }) {
    return AddOutputDeviceVmState(
      zoneId: zoneId != null ? zoneId() : this.zoneId,
      outputDeviceName: outputDeviceName != null ? outputDeviceName() : this.outputDeviceName,
      outputProductId: outputProductId != null ? outputProductId() : this.outputProductId,
      audioChannel: audioChannel != null ? audioChannel() : this.audioChannel,
      connectionType: connectionType != null ? connectionType() : this.connectionType,
      selectedStream: selectedStream != null ? selectedStream() : this.selectedStream,
      selectedMonoChannel: selectedMonoChannel != null ? selectedMonoChannel() : this.selectedMonoChannel,
      selectedLeftChannel: selectedLeftChannel != null ? selectedLeftChannel() : this.selectedLeftChannel,
      selectedRightChannel: selectedRightChannel != null ? selectedRightChannel() : this.selectedRightChannel,
    );
  }
}
