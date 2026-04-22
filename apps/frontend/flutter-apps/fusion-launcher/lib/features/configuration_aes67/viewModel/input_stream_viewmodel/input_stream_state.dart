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
  final List<Aes67SessionEntry> sessions;
  final bool isLoadingSessions;

  const InputStreamLoaded({
    required this.stream,
    this.isSessionSectionExpanded = true,
    this.sessions = const <Aes67SessionEntry>[],
    this.isLoadingSessions = false,
  });

  InputStreamLoaded copyWith({
    Aes67Config? stream,
    bool? isSessionSectionExpanded,
    List<Aes67SessionEntry>? sessions,
    bool? isLoadingSessions,
  }) {
    return InputStreamLoaded(
      stream: stream ?? this.stream,
      isSessionSectionExpanded: isSessionSectionExpanded ?? this.isSessionSectionExpanded,
      sessions: sessions ?? this.sessions,
      isLoadingSessions: isLoadingSessions ?? this.isLoadingSessions,
    );
  }
}

class InputStreamError extends InputStreamState {
  final String message;
  const InputStreamError({required this.message});
}
