import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/output_product.dart';

class AddOutputDeviceRepository {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  /// Persists [device] to the project's hardware store, links it to [zoneId]
  /// via the zone's first listening area, and when the connection is AES67,
  /// assigns the selected stream channels.
  void saveOutputDevice({
    required OutputDevice device,
    String? zoneId,
    Aes67Config? selectedStream,
    int? selectedMonoChannel,
    int? selectedLeftChannel,
    int? selectedRightChannel,
  }) {
    OutputDevice deviceToSave = device;

    if (zoneId != null) {
      final List<ListeningArea> areas = _projectViewModel.getListeningAreasForZone(zoneId: zoneId);
      final ListeningArea? firstListeningArea = areas.firstOrNull;

      if (firstListeningArea != null) {
        final FloorModel? floor = _projectViewModel.getFloorForListeningArea(areaId: firstListeningArea.id);
        deviceToSave = device.copyWith(
          locationEntity: LocationModel(
            listeningAreaId: firstListeningArea.id,
            floorId: floor?.id,
          ),
        );
      }
    }

    _projectViewModel.addHardware(hardware: deviceToSave);

    if (deviceToSave.connectionType == OutputConnectionType.aes67Output && selectedStream != null) {
      final List<AssignedStreamChannel> channels = _buildChannelAssignments(
        stream: selectedStream,
        audioChannel: deviceToSave.audioChannel,
        selectedMonoChannel: selectedMonoChannel,
        selectedLeftChannel: selectedLeftChannel,
        selectedRightChannel: selectedRightChannel,
      );

      if (channels.isNotEmpty) {
        _projectViewModel.assignStreamChannelsToOutputDevice(
          outputDeviceId: deviceToSave.id,
          channels: channels,
        );
      }
    }
  }

  /// Returns all output devices saved in the current project.
  List<OutputDevice> getAllOutputDevices() => _projectViewModel.getAllHardware().whereType<OutputDevice>().toList();

  /// Returns the AES67 stream-channel assignments for [outputDeviceId].
  List<AssignedStreamChannel> getStreamChannelsForOutputDevice(String outputDeviceId) => _projectViewModel.getStreamChannelsForOutputDevice(outputDeviceId);

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<AssignedStreamChannel> _buildChannelAssignments({
    required Aes67Config stream,
    required AudioChannel audioChannel,
    int? selectedMonoChannel,
    int? selectedLeftChannel,
    int? selectedRightChannel,
  }) {
    String channelName(int channelNumber) {
      final List<Aes67ChannelConfig> configs = stream.channelConfigs;
      if (channelNumber >= 1 && channelNumber <= configs.length) {
        return configs[channelNumber - 1].label ?? 'Channel $channelNumber';
      }
      return 'Channel $channelNumber';
    }

    if (audioChannel == AudioChannel.mono && selectedMonoChannel != null) {
      return <AssignedStreamChannel>[
        AssignedStreamChannel(
          streamId: stream.id,
          channelNumber: selectedMonoChannel,
          channelName: channelName(selectedMonoChannel),
        ),
      ];
    }

    if (audioChannel == AudioChannel.stereo) {
      return <AssignedStreamChannel>[
        if (selectedLeftChannel != null)
          AssignedStreamChannel(
            streamId: stream.id,
            channelNumber: selectedLeftChannel,
            channelName: channelName(selectedLeftChannel),
          ),
        if (selectedRightChannel != null)
          AssignedStreamChannel(
            streamId: stream.id,
            channelNumber: selectedRightChannel,
            channelName: channelName(selectedRightChannel),
          ),
      ];
    }

    return <AssignedStreamChannel>[];
  }
}
