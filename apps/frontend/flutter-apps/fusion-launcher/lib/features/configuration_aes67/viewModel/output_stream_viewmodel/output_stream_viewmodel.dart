import 'package:flutter_bloc/flutter_bloc.dart';

part 'output_stream_state.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

List<OutputChannelConfig> _buildChannels(int count) => List<OutputChannelConfig>.generate(
  count,
  (int i) => OutputChannelConfig(
    channelNumber: i + 1,
    name: 'Channel ${i + 1}',
  ),
);

// ── Cubit ─────────────────────────────────────────────────────────────────────

class OutputStreamViewmodel extends Cubit<OutputStreamState> {
  OutputStreamViewmodel() : super(const OutputStreamInitial());

  void init() {
    emit(const OutputStreamLoading());

    // Mock initial data — replace with repo call
    emit(
      OutputStreamLoaded(
        name: 'Stage Inputs',
        channelCount: 2,
        channelConfigs: _buildChannels(2),
        isAdvancedExpanded: false,
        sessionId: 'Fusion External System AES',
        ipAddress: '239.69.1.21',
        bitDepth: '24 bit',
        sampleRate: '48 kHz',
        packetTime: '1 ms',
      ),
    );
  }

  // ── Name ──────────────────────────────────────────────────────────────────

  void updateName(String name) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(name: name));
  }

  // ── Channel count ─────────────────────────────────────────────────────────

  void updateChannelCount(int count) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(
      s.copyWith(
        channelCount: count,
        channelConfigs: _buildChannels(count),
      ),
    );
  }

  // ── Per-channel name ──────────────────────────────────────────────────────

  void updateChannelName(int channelNumber, String name) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null) return;
    final List<OutputChannelConfig> updated =
        s.channelConfigs.map((OutputChannelConfig c) {
          return c.channelNumber == channelNumber ? c.copyWith(name: name) : c;
        }).toList();
    emit(s.copyWith(channelConfigs: updated));
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
    emit(s.copyWith(sessionId: value));
  }

  void updateIpAddress(String value) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(ipAddress: value));
  }

  void updateBitDepth(String? value) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null || value == null) return;
    emit(s.copyWith(bitDepth: value));
  }

  void updateSampleRate(String? value) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null || value == null) return;
    emit(s.copyWith(sampleRate: value));
  }

  void updatePacketTime(String? value) {
    final OutputStreamLoaded? s = _loaded;
    if (s == null || value == null) return;
    emit(s.copyWith(packetTime: value));
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void exportSdp() {
    // Hook: launch file-save dialog / share sheet
  }

  void save() {
    // Hook: persist to repo / emit success
  }

  // ── Private helper ────────────────────────────────────────────────────────

  OutputStreamLoaded? get _loaded {
    final OutputStreamState s = state;
    return s is OutputStreamLoaded ? s : null;
  }
}
