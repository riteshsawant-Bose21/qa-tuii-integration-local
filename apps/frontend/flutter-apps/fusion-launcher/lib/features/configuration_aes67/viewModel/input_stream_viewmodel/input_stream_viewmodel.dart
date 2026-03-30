import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/models/response_callback.dart';

part 'input_stream_state.dart';

class InputStreamViewmodel extends Cubit<InputStreamState> {
  final ProjectViewModel _projectViewModel;
  final String? _streamId;

  InputStreamViewmodel({
    required ProjectViewModel projectViewModel,
    String? streamId,
  }) : _projectViewModel = projectViewModel,
       _streamId = streamId,
       super(const InputStreamInitial());

  void init({Aes67Config? existingStream}) {
    emit(const InputStreamLoading());

    try {
      Aes67Config stream;

      if (existingStream != null) {
        // Editing existing stream
        stream = existingStream;
      } else if (_streamId != null) {
        // Load from ProjectViewModel
        final Aes67Config? loadedStream = _projectViewModel.getAes67InputStreamById(_streamId!);
        if (loadedStream == null) {
          emit(const InputStreamError(message: 'Stream not found'));
          return;
        }
        stream = loadedStream;
      } else {
        // Create new stream with defaults
        stream = Aes67Config(
          name: 'New Input Stream',
          streamType: Aes67StreamType.input,
        );
      }

      emit(
        InputStreamLoaded(
          stream: stream,
          isSessionSectionExpanded: false,
          apiSessions: const <Aes67SessionEntry>[],
          isLoadingSessions: false,
        ),
      );

      // Fetch sessions from API
      fetchSessions();
    } catch (e) {
      emit(InputStreamError(message: e.toString()));
    }
  }

  // ── Fetch sessions from API ───────────────────────────────────────────────

  /// Sample sessions for testing purposes
  static List<Aes67SessionEntry> get _sampleSessions => <Aes67SessionEntry>[
    const Aes67SessionEntry(
      id: 'session-1',
      sessionId: 'Dante-Mixer-01',
      channels: 8,
      ipVersion: 'IPv4',
      ipAddress: '239.100.9.16',
      port: 5010,
      bitDepth: 16,
      sampleRate: '45000 Hz',
      packetTime: '2 ms',
      isDanteDevice: true,
      channelLabels: <String>['Mix_L', 'Mix_R', 'Aux_1', 'Aux_2', 'Mon_L', 'Mon_R', 'FX_1', 'FX_2'],
    ),
    const Aes67SessionEntry(
      id: 'session-2',
      sessionId: 'AES67-Source-A',
      channels: 2,
      ipVersion: 'IPv4',
      ipAddress: '239.69.100.2',
      port: 5020,
      bitDepth: 20,
      sampleRate: '48000 Hz',
      packetTime: '3 ms',
      isDanteDevice: false,
      channelLabels: <String>['Left', 'Right'],
    ),
    const Aes67SessionEntry(
      id: 'session-3',
      sessionId: 'Dante-Amp-02',
      channels: 4,
      ipVersion: 'IPv4',
      ipAddress: '239.2.10.100',
      port: 5030,
      bitDepth: 24,
      sampleRate: '47000 Hz',
      packetTime: '4 ms',
      isDanteDevice: true,
      channelLabels: <String>['Amp_Ch1', 'Amp_Ch2', 'Amp_Ch3', 'Amp_Ch4'],
    ),
    const Aes67SessionEntry(
      id: 'session-4',
      sessionId: 'Livewire-Console',
      channels: 16,
      ipVersion: 'IPv4',
      ipAddress: '198.409.99.6',
      port: 5040,
      bitDepth: 26,
      sampleRate: '46000 Hz',
      packetTime: '1 ms',
      isDanteDevice: false,
      channelLabels: <String>[
        'Input_1',
        'Input_2',
        'Input_3',
        'Input_4',
        'Input_5',
        'Input_6',
        'Input_7',
        'Input_8',
        'Input_9',
        'Input_10',
        'Input_11',
        'Input_12',
        'Input_13',
        'Input_14',
        'Input_15',
        'Input_16',
      ],
    ),
  ];

  Future<void> fetchSessions() async {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;

    emit(s.copyWith(isLoadingSessions: true));

    try {
      final ResponseCallback<dynamic> responseCallback = await serviceLocator<FusionNetworkClient>().get(api: FusionApiEndpoint.sapSessions);

      if (responseCallback.success && responseCallback.data != null) {
        final Map<String, dynamic> data = json.decode(responseCallback.data);
        final Map<String, dynamic> sessionsData = data['sessions'] as Map<String, dynamic>;

        final List<Aes67SessionEntry> sessions =
            sessionsData.entries.map((MapEntry<String, dynamic> entry) {
              final Map<String, dynamic> sessionData = entry.value;
              final dynamic connectionInfo = sessionData['description']['ConnectionInformation'];
              final String ipAddress = (connectionInfo['Address']['Address'] as String).split('/').first;
              final int port = connectionInfo['Port'] as int? ?? 5004;
              final int channelCount = sessionData['description']['MediaDescription']?['Channels'] as int? ?? 2;

              // Get channel labels from API, or generate default labels if not provided
              final List<String> channelLabels =
                  (sessionData['description']['MediaDescription']?['ChannelLabels'] as List<dynamic>?)?.map((dynamic e) => e as String).toList() ??
                  List<String>.generate(channelCount, (int i) => 'Ch${i + 1}');

              return Aes67SessionEntry(
                id: entry.key,
                sessionId: sessionData['description']['SessionName'] ?? entry.key,
                channels: channelCount,
                ipVersion: 'IPv4',
                ipAddress: ipAddress,
                port: port,
                bitDepth: sessionData['description']['MediaDescription']?['BitDepth'] as int? ?? 24,
                sampleRate: '${sessionData['description']['MediaDescription']?['SampleRate'] ?? 48000} Hz',
                packetTime: '${sessionData['description']['MediaDescription']?['PacketTime'] ?? 1} ms',
                isDanteDevice: sessionData['description']['MediaDescription']?['IsDanteDevice'] as bool? ?? false,
                channelLabels: channelLabels,
              );
            }).toList();

        final InputStreamLoaded? current = _loaded;
        if (current != null) {
          // Use API sessions if available, otherwise use sample data for testing
          final List<Aes67SessionEntry> finalSessions = sessions.isNotEmpty ? sessions : _sampleSessions;
          emit(current.copyWith(apiSessions: finalSessions, isLoadingSessions: false));
        }
      } else {
        // API failed, use sample data for testing
        final InputStreamLoaded? current = _loaded;
        if (current != null) {
          emit(current.copyWith(apiSessions: _sampleSessions, isLoadingSessions: false));
        }
      }
    } catch (e) {
      // API error, use sample data for testing
      final InputStreamLoaded? current = _loaded;
      if (current != null) {
        emit(current.copyWith(apiSessions: _sampleSessions, isLoadingSessions: false));
      }
    }
  }

  // ── Name ──────────────────────────────────────────────────────────────────

  void updateName(String name) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(stream: s.stream.copyWith(name: name)));
  }

  // ── Channel count ─────────────────────────────────────────────────────────

  void updateChannelCount(int count) {
    final InputStreamLoaded? s = _loaded;
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

  // ── Per-channel config ────────────────────────────────────────────────────

  void updateChannelLabel(int channelNumber, String label) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    final List<Aes67ChannelConfig> updated =
        s.channelConfigs.map((Aes67ChannelConfig c) {
          return c.channelNumber == channelNumber ? c.copyWith(label: label) : c;
        }).toList();
    emit(s.copyWith(stream: s.stream.copyWith(channelConfigs: updated)));
  }

  void updateChannelAssignment(int channelNumber, String assignedTo) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    final List<Aes67ChannelConfig> updated =
        s.channelConfigs.map((Aes67ChannelConfig c) {
          return c.channelNumber == channelNumber ? c.copyWith(assignedTo: assignedTo) : c;
        }).toList();
    emit(s.copyWith(stream: s.stream.copyWith(channelConfigs: updated)));
  }

  // ── Assigned to (top-level) ────────────────────────────────────────────────
  // When user selects from the "Assigned to" dropdown, we find the session by sessionId
  // and store its id as selectedSessionId, also copy session data to stream

  void updateAssignedTo(String? sessionIdValue) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;

    if (sessionIdValue == null) {
      emit(
        s.copyWith(
          stream: s.stream.copyWith(
            clearSelectedSessionId: true,
            ipAddress: '',
            port: 0,
            device: '',
            streamOrAdvertisement: '',
          ),
        ),
      );
      return;
    }

    // Find the session by its sessionId (the display name shown in dropdown)
    final Aes67SessionEntry? session = s.apiSessions.where((Aes67SessionEntry sess) => sess.sessionId == sessionIdValue).firstOrNull;

    if (session != null) {
      emit(
        s.copyWith(
          stream: s.stream.copyWith(
            selectedSessionId: session.id,
            ipAddress: session.ipAddress,
            port: session.port,
            device: session.sessionId,
            streamOrAdvertisement: session.sessionId,
            channels: session.channels,
            channelConfigs: List<Aes67ChannelConfig>.generate(
              session.channels,
              (int i) => Aes67ChannelConfig(
                channelNumber: i + 1,
                label: session.channelLabels.length > i ? session.channelLabels[i] : 'Ch${i + 1}',
                assignedTo: session.channelLabels.length > i ? session.channelLabels[i] : 'Ch${i + 1}',
              ),
            ),
            bitDepth: session.bitDepth.toString(),
          ),
        ),
      );
    } else {
      emit(
        s.copyWith(
          stream: s.stream.copyWith(
            clearSelectedSessionId: true,
          ),
        ),
      );
    }
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

    if (newId == null) {
      // Deselecting - clear session-related fields
      emit(
        s.copyWith(
          stream: s.stream.copyWith(
            clearSelectedSessionId: true,
            ipAddress: '',
            port: 0,
            device: '',
            streamOrAdvertisement: '',
          ),
        ),
      );
    } else {
      // Selecting - copy session data to stream
      final Aes67SessionEntry? session = s.apiSessions.where((Aes67SessionEntry sess) => sess.id == id).firstOrNull;
      if (session != null) {
        emit(
          s.copyWith(
            stream: s.stream.copyWith(
              selectedSessionId: newId,
              ipAddress: session.ipAddress,
              port: session.port,
              device: session.sessionId,
              streamOrAdvertisement: session.sessionId,
            ),
          ),
        );
      }
    }
  }

  void toggleDanteDevice(String id) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;

    final List<Aes67SessionEntry> updatedSessions =
        s.apiSessions.map((Aes67SessionEntry session) {
          if (session.id == id) {
            return session.copyWith(isDanteDevice: !session.isDanteDevice);
          }
          return session;
        }).toList();

    // If the toggled session's isDanteDevice just became false and it was the
    // current selected session, clear selectedSessionId
    final Aes67SessionEntry toggled = updatedSessions.firstWhere((Aes67SessionEntry se) => se.id == id);
    String? newSelectedSessionId = s.selectedSessionId;
    if (!toggled.isDanteDevice && newSelectedSessionId == toggled.id) {
      newSelectedSessionId = null;
    }
    // If it became true, auto-assign if nothing is assigned yet
    if (toggled.isDanteDevice && newSelectedSessionId == null) {
      newSelectedSessionId = toggled.id;
    }

    emit(
      s.copyWith(
        apiSessions: updatedSessions,
        stream: s.stream.copyWith(
          selectedSessionId: newSelectedSessionId,
          clearSelectedSessionId: newSelectedSessionId == null,
        ),
      ),
    );
  }

  void updateSession(Aes67SessionEntry updatedSession) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;

    final List<Aes67SessionEntry> updated =
        s.apiSessions.map((Aes67SessionEntry session) {
          return session.id == updatedSession.id ? updatedSession : session;
        }).toList();

    emit(s.copyWith(apiSessions: updated));
  }

  void addSession(Aes67SessionEntry session) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;

    final List<Aes67SessionEntry> updated = <Aes67SessionEntry>[...s.apiSessions, session];
    emit(s.copyWith(apiSessions: updated));
  }

  void removeSession(String sessionId) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;

    final List<Aes67SessionEntry> updated = s.apiSessions.where((Aes67SessionEntry session) => session.id != sessionId).toList();

    // Clear selection if removed session was selected
    final bool clearSelection = s.selectedSessionId == sessionId;
    emit(
      s.copyWith(
        apiSessions: updated,
        stream: clearSelection ? s.stream.copyWith(clearSelectedSessionId: true) : null,
      ),
    );
  }

  void confirmSelectSession() {
    // Save / apply the selected session
  }

  void importSdp() {
    // Launch SDP file picker
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  void save() {
    final InputStreamLoaded? loaded = _loaded;
    if (loaded == null) return;

    try {
      if (_streamId != null) {
        // Update existing stream
        _projectViewModel.updateAes67InputStream(stream: loaded.stream);
      } else {
        // Add new stream
        _projectViewModel.addAes67InputStream(stream: loaded.stream);
      }
    } catch (e) {
      emit(InputStreamError(message: 'Failed to save: ${e.toString()}'));
    }
  }

  // ── Get current stream ────────────────────────────────────────────────────

  Aes67Config? getCurrentStream() {
    final InputStreamLoaded? s = _loaded;
    return s?.stream;
  }

  // ── Private helper ────────────────────────────────────────────────────────

  InputStreamLoaded? get _loaded {
    final InputStreamState s = state;
    return s is InputStreamLoaded ? s : null;
  }
}
