part of 'input_stream_viewmodel.dart';

sealed class InputStreamState {
  const InputStreamState();
}

class InputStreamInitial extends InputStreamState {
  const InputStreamInitial();
}

class InputStreamLoading extends InputStreamState {
  const InputStreamLoading();
}

class InputStreamLoaded extends InputStreamState {
  final Aes67Config stream;
  final bool isSessionSectionExpanded;
  final List<Aes67SessionEntry> apiSessions; // Sessions fetched from API
  final bool isLoadingSessions;

  const InputStreamLoaded({
    required this.stream,
    this.isSessionSectionExpanded = false,
    this.apiSessions = const <Aes67SessionEntry>[],
    this.isLoadingSessions = false,
  });

  /// Convenience getters from stream
  String get name => stream.name;
  int get channelCount => stream.channels;
  List<Aes67ChannelConfig> get channelConfigs => stream.channelConfigs;
  String? get selectedSessionId => stream.selectedSessionId;

  /// Sessions come from API, not stored in stream
  List<Aes67SessionEntry> get sessions => apiSessions;

  /// Derive assignedTo from selectedSessionId - find the session and return its sessionId
  String? get assignedTo {
    if (selectedSessionId == null) return null;
    final Aes67SessionEntry? session = apiSessions.where((Aes67SessionEntry s) => s.id == selectedSessionId).firstOrNull;
    return session?.sessionId;
  }

  /// Get list of all session IDs for the "Assigned to" dropdown
  List<String> get danteAssignableOptions => apiSessions.map((Aes67SessionEntry s) => s.sessionId).toList();

  /// Get channel options from the selected session (from API's channelLabels)
  List<String> get selectedSessionChannelOptions {
    if (selectedSessionId == null) return <String>[];
    final Aes67SessionEntry? session = apiSessions.where((Aes67SessionEntry s) => s.id == selectedSessionId).firstOrNull;
    if (session == null) return <String>[];
    // Return channel labels from the session (comes from API)
    return session.channelLabels;
  }

  InputStreamLoaded copyWith({
    Aes67Config? stream,
    bool? isSessionSectionExpanded,
    List<Aes67SessionEntry>? apiSessions,
    bool? isLoadingSessions,
  }) {
    return InputStreamLoaded(
      stream: stream ?? this.stream,
      isSessionSectionExpanded: isSessionSectionExpanded ?? this.isSessionSectionExpanded,
      apiSessions: apiSessions ?? this.apiSessions,
      isLoadingSessions: isLoadingSessions ?? this.isLoadingSessions,
    );
  }
}

class InputStreamError extends InputStreamState {
  final String message;
  const InputStreamError({required this.message});
}
