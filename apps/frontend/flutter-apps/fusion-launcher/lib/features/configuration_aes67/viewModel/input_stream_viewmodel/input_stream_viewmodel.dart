import 'package:flutter_bloc/flutter_bloc.dart';

part 'input_stream_state.dart';

/// Channel label options per channel count
const Map<int, List<String>> _channelLabels = <int, List<String>>{
  1: <String>['Mono'],
  2: <String>['Left', 'Right'],
  3: <String>['Left', 'Right', 'Center'],
  4: <String>['Left', 'Right', 'Center', 'LFE'],
  5: <String>['Left', 'Right', 'Center', 'LFE', 'Surround'],
  6: <String>['Left', 'Right', 'Center', 'LFE', 'Ls', 'Rs'],
  7: <String>['Left', 'Right', 'Center', 'LFE', 'Ls', 'Rs', 'Cs'],
  8: <String>['Left', 'Right', 'Center', 'LFE', 'Lss', 'Rss', 'Lrs', 'Rrs'],
};

List<Aes67ChannelConfig> _buildDefaultChannels(int count) {
  final List<String> labels = _channelLabels[count] ?? List<String>.generate(count, (int i) => 'Ch ${i + 1}');
  return List<Aes67ChannelConfig>.generate(
    count,
    (int i) => Aes67ChannelConfig(
      channelNumber: i + 1,
      label: labels[i],
      assignedTo: null,
    ),
  );
}

class InputStreamViewmodel extends Cubit<InputStreamState> {
  InputStreamViewmodel() : super(const InputStreamInitial());

  void init({required Aes67AppMode mode}) {
    emit(const InputStreamLoading());

    // Mock data — replace with real repo call
    emit(
      InputStreamLoaded(
        mode: mode,
        name: 'EX-8ML Wireless ..',
        assignedTo: null,
        channelCount: 2,
        channelConfigs: _buildDefaultChannels(2),
        isSessionSectionExpanded: false,
        selectedSessionId: null,
        sessions: const <Aes67SessionEntry>[
          Aes67SessionEntry(
            id: 's1',
            sessionId: 'Stage EX4ML1',
            channels: 2,
            ipVersion: 'IPv4',
            ipAddress: '239.100.9.16',
            port: 5004,
            bitDepth: 24,
            sampleRate: '48kHz',
            packetTime: '1ms',
            isDanteDevice: false,
          ),
          Aes67SessionEntry(
            id: 's2',
            sessionId: 'Main EX1280',
            channels: 8,
            ipVersion: 'IPv4',
            ipAddress: '239.2.10.100',
            port: 5004,
            bitDepth: 24,
            sampleRate: '48kHz',
            packetTime: '1ms',
            isDanteDevice: false,
          ),
          Aes67SessionEntry(
            id: 's3',
            sessionId: 'Atterotech EP21',
            channels: 2,
            ipVersion: 'IPv4',
            ipAddress: '239.69.200.5',
            port: 5005,
            bitDepth: 24,
            sampleRate: '48kHz',
            packetTime: '1ms',
            isDanteDevice: false,
          ),
        ],
      ),
    );
  }

  // ── Name ──────────────────────────────────────────────────────────────────

  void updateName(String name) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(name: name));
  }

  // ── Channel count ─────────────────────────────────────────────────────────

  void updateChannelCount(int count) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(
      s.copyWith(
        channelCount: count,
        channelConfigs: _buildDefaultChannels(count),
      ),
    );
  }

  // ── Per-channel config ────────────────────────────────────────────────────

  void updateChannelLabel(int channelNumber, String label) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    final List<Aes67ChannelConfig> updated =
        s.channelConfigs.map((Aes67ChannelConfig c) {
          return c.channelNumber == channelNumber ? c.copyWith(label: label) : c;
        }).toList();
    emit(s.copyWith(channelConfigs: updated));
  }

  void updateChannelAssignment(int channelNumber, String assignedTo) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    final List<Aes67ChannelConfig> updated =
        s.channelConfigs.map((Aes67ChannelConfig c) {
          return c.channelNumber == channelNumber ? c.copyWith(assignedTo: assignedTo) : c;
        }).toList();
    emit(s.copyWith(channelConfigs: updated));
  }

  // ── Assigned to (top-level) ────────────────────────────────────────────────

  void updateAssignedTo(String? value) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(assignedTo: value));
  }

  // ── Session section ───────────────────────────────────────────────────────

  void toggleSessionSection() {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(isSessionSectionExpanded: !s.isSessionSectionExpanded));
  }

  void selectSession(String id) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    // Toggle off if already selected
    final String? newId = s.selectedSessionId == id ? null : id;
    emit(s.copyWith(selectedSessionId: newId));
  }

  void toggleDanteDevice(String id) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;

    final List<Aes67SessionEntry> updatedSessions =
        s.sessions.map((Aes67SessionEntry session) {
          if (session.id == id) {
            return session.copyWith(isDanteDevice: !session.isDanteDevice);
          }
          return session;
        }).toList();

    // If the toggled session's isDanteDevice just became false and it was the
    // current assignedTo, clear assignedTo
    final Aes67SessionEntry toggled = updatedSessions.firstWhere((Aes67SessionEntry s) => s.id == id);
    String? newAssignedTo = s.assignedTo;
    if (!toggled.isDanteDevice && newAssignedTo == toggled.sessionId) {
      newAssignedTo = null;
    }
    // If it became true, auto-assign if nothing is assigned yet
    if (toggled.isDanteDevice && newAssignedTo == null) {
      newAssignedTo = toggled.sessionId;
    }

    emit(
      s.copyWith(
        sessions: updatedSessions,
        assignedTo: newAssignedTo,
      ),
    );
  }

  void confirmSelectSession() {
    // Save / apply the selected session — hook for real persistence
  }

  void importSdp() {
    // Launch SDP file picker — hook for real implementation
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  InputStreamLoaded? get _loaded {
    final InputStreamState s = state;
    return s is InputStreamLoaded ? s : null;
  }
}
