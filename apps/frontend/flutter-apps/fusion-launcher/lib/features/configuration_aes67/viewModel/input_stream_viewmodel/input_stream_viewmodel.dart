import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/models/response_callback.dart';
import 'package:fusion_lib/service/aes67/session_sync_service.dart';

part 'input_stream_state.dart';

class InputStreamViewmodel extends Cubit<InputStreamState> {
  final ProjectViewModel _projectViewModel;
  final String? _streamId;
  final SessionSyncService _sessionService;

  InputStreamViewmodel({
    required ProjectViewModel projectViewModel,
    String? streamId,
    SessionSyncService? sessionService,
  }) : _projectViewModel = projectViewModel,
       _streamId = streamId,
       _sessionService = sessionService ?? SessionSyncService(networkClient: serviceLocator<FusionNetworkClient>()),
       super(const InputStreamInitial());

  // ── Session helpers used internally ─────────────────────────────────────
  String get vip => serviceLocator<ProjectViewModel>().virtualIP ?? "";

  Aes67SessionEntry? _sessionById(InputStreamLoaded s, String id) => s.sessions.where((Aes67SessionEntry e) => e.id == id).firstOrNull;

  Aes67SessionEntry? _sessionByName(InputStreamLoaded s, String name) => s.sessions.where((Aes67SessionEntry e) => e.sessionId == name).firstOrNull;

  void init({Aes67Config? existingStream}) {
    emit(const InputStreamLoading());

    try {
      Aes67Config stream;

      if (existingStream != null) {
        // Editing existing stream
        stream = existingStream;
      } else if (_streamId != null) {
        // Load from ProjectViewModel
        final Aes67Config? loadedStream = _projectViewModel.getAes67InputStreamById(_streamId);
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

      emit(InputStreamLoaded(stream: stream));

      /// Fetch sessions from API only when connected (control mode)
      if (_projectViewModel.isInControlMode) {
        fetchSessions();
      }
    } catch (e) {
      emit(InputStreamError(message: e.toString()));
    }
  }

  // ── Fetch sessions from API ───────────────────────────────────────────────

  Future<void> fetchSessions() async {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;

    emit(s.copyWith(isLoadingSessions: true));

    try {
      final ResponseCallback<List<Aes67SessionEntry>> result = await _sessionService.getSessions(vip: vip);
      final List<Aes67SessionEntry> sessions = result.success ? (result.data ?? <Aes67SessionEntry>[]) : <Aes67SessionEntry>[];
      emit((_loaded ?? s).copyWith(sessions: sessions, isLoadingSessions: false));
    } catch (_) {
      emit((_loaded ?? s).copyWith(sessions: <Aes67SessionEntry>[], isLoadingSessions: false));
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
        s.stream.channelConfigs.map((Aes67ChannelConfig c) {
          return c.channelNumber == channelNumber ? c.copyWith(label: label) : c;
        }).toList();
    emit(s.copyWith(stream: s.stream.copyWith(channelConfigs: updated)));
  }

  void updateChannelAssignment(int channelNumber, String assignedTo) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    final List<Aes67ChannelConfig> updated =
        s.stream.channelConfigs.map((Aes67ChannelConfig c) {
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
    final Aes67SessionEntry? session = _sessionByName(s, sessionIdValue);

    emit(
      s.copyWith(
        stream: session != null ? _streamFromSession(s.stream, session) : s.stream.copyWith(clearSelectedSessionId: true),
      ),
    );
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
    final String? newId = s.stream.selectedSessionId == id ? null : id;

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
      final Aes67SessionEntry? session = _sessionById(s, id);
      if (session != null) {
        emit(s.copyWith(stream: _streamFromSession(s.stream, session, overrideId: newId)));
      }
    }
  }

  void toggleDanteDevice(String id) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;

    final List<Aes67SessionEntry> updated =
        s.sessions.map((Aes67SessionEntry session) {
          return session.id == id ? session.copyWith(isDanteDevice: !session.isDanteDevice) : session;
        }).toList();

    final Aes67SessionEntry toggled = updated.firstWhere((Aes67SessionEntry se) => se.id == id);
    String? newSelectedId = s.stream.selectedSessionId;
    if (!toggled.isDanteDevice && newSelectedId == toggled.id) newSelectedId = null;
    if (toggled.isDanteDevice && newSelectedId == null) newSelectedId = toggled.id;

    emit(
      s.copyWith(
        sessions: updated,
        stream: s.stream.copyWith(
          selectedSessionId: newSelectedId,
          clearSelectedSessionId: newSelectedId == null,
        ),
      ),
    );
  }

  void updateSession(Aes67SessionEntry updatedSession) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(
      s.copyWith(
        sessions:
            s.sessions.map((Aes67SessionEntry session) {
              return session.id == updatedSession.id ? updatedSession : session;
            }).toList(),
      ),
    );
  }

  void addSession(Aes67SessionEntry session) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(sessions: <Aes67SessionEntry>[...s.sessions, session]));
  }

  void removeSession(String sessionId) {
    final InputStreamLoaded? s = _loaded;
    if (s == null) return;
    final bool clearSelection = s.stream.selectedSessionId == sessionId;
    emit(
      s.copyWith(
        sessions: s.sessions.where((Aes67SessionEntry session) => session.id != sessionId).toList(),
        stream: clearSelection ? s.stream.copyWith(clearSelectedSessionId: true) : null,
      ),
    );
  }

  void confirmSelectSession() {}

  void importSdp() {}

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

  Aes67Config? getCurrentStream() => _loaded?.stream;

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Populates [current] stream fields from the selected [session].
  Aes67Config _streamFromSession(Aes67Config current, Aes67SessionEntry session, {String? overrideId}) {
    final List<Aes67ChannelConfig> clearedChannels = current.channelConfigs.map((Aes67ChannelConfig c) => c.copyWith(clearAssignedTo: true)).toList();

    return current.copyWith(
      selectedSessionId: overrideId ?? session.id,
      ipAddress: session.ipAddress,
      port: session.port,
      device: session.sessionId,
      streamOrAdvertisement: session.sessionId,
      bitDepth: session.bitDepth.toString(),
      packetTime: session.packetTime,
      channelConfigs: clearedChannels,
    );
  }

  InputStreamLoaded? get _loaded {
    final InputStreamState s = state;
    return s is InputStreamLoaded ? s : null;
  }
}
