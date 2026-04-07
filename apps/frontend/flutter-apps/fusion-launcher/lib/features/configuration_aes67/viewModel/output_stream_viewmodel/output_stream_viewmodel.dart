import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

part 'output_stream_state.dart';

// ── Cubit ─────────────────────────────────────────────────────────────────────

class OutputStreamViewmodel extends Cubit<OutputStreamState> {
  final ProjectViewModel _projectViewModel;
  final String? _streamId;

  OutputStreamViewmodel({
    required ProjectViewModel projectViewModel,
    String? streamId,
  }) : _projectViewModel = projectViewModel,
       _streamId = streamId,
       super(const OutputStreamInitial());

  void init({Aes67Config? existingStream}) {
    emit(const OutputStreamLoading());

    try {
      Aes67Config stream;

      if (existingStream != null) {
        // Editing existing stream
        stream = existingStream;
      } else if (_streamId != null) {
        // Load from ProjectViewModel
        final Aes67Config? loadedStream = _projectViewModel.getAes67OutputStreamById(_streamId!);
        if (loadedStream == null) {
          emit(const OutputStreamError(message: 'Stream not found'));
          return;
        }
        stream = loadedStream;
      } else {
        // Create new stream with defaults
        stream = Aes67Config(
          name: 'New Output Stream',
          streamType: Aes67StreamType.output,
          streamOrAdvertisement: 'Fusion External System AES',
          ipAddress: '239.69.1.21',
        );
      }

      emit(
        OutputStreamLoaded(
          stream: stream,
          isAdvancedExpanded: false,
        ),
      );
    } catch (e) {
      emit(OutputStreamError(message: e.toString()));
    }
  }

  // ── Name ──────────────────────────────────────────────────────────────────

  void updateName(String name) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(stream: s.stream.copyWith(name: name)));
  }

  // ── Channel count ─────────────────────────────────────────────────────────

  void updateChannelCount(int count) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(
      s.copyWith(
        stream: s.stream.copyWith(
          channels: count,
          channelConfigs: Aes67Config.buildDefaultChannels(count),
        ),
      ),
    );
  }

  // ── Per-channel name ──────────────────────────────────────────────────────

  void updateChannelName(int channelNumber, String name) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null) return;
    final List<Aes67ChannelConfig> updated =
        s.channelConfigs.map((Aes67ChannelConfig c) {
          return c.channelNumber == channelNumber ? c.copyWith(label: name) : c;
        }).toList();
    emit(s.copyWith(stream: s.stream.copyWith(channelConfigs: updated)));
  }

  // ── Advanced section ──────────────────────────────────────────────────────

  void toggleAdvanced() {
    final OutputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(isAdvancedExpanded: !s.isAdvancedExpanded));
  }

  void updateSessionId(String value) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(stream: s.stream.copyWith(streamOrAdvertisement: value)));
  }

  void updateIpAddress(String value) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(stream: s.stream.copyWith(ipAddress: value)));
  }

  void updateBitDepth(String? value) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null || value == null) return;
    emit(s.copyWith(stream: s.stream.copyWith(bitDepth: value)));
  }

  void updateSampleRate(String? value) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null || value == null) return;
    emit(s.copyWith(stream: s.stream.copyWith(sampleRate: value)));
  }

  void updatePacketTime(String? value) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null || value == null) return;
    emit(s.copyWith(stream: s.stream.copyWith(packetTime: value)));
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void exportSdp() {
    // Hook: launch file-save dialog / share sheet
  }

  void save() {
    final OutputStreamLoaded? s = _loaded;
    if (s == null) return;

    try {
      if (_streamId != null) {
        // Update existing stream
        _projectViewModel.updateAes67OutputStream(stream: s.stream);
      } else {
        // Add new stream
        _projectViewModel.addAes67OutputStream(stream: s.stream);
      }
    } catch (e) {
      emit(OutputStreamError(message: 'Failed to save: ${e.toString()}'));
    }
  }

  // ── Get current stream ────────────────────────────────────────────────────

  Aes67Config? getCurrentStream() {
    final OutputStreamLoaded? s = _loaded;
    return s?.stream;
  }

  // ── Private helper ────────────────────────────────────────────────────────

  OutputStreamLoaded? get _loaded {
    final OutputStreamState s = state;
    return s is OutputStreamLoaded ? s : null;
  }
}
