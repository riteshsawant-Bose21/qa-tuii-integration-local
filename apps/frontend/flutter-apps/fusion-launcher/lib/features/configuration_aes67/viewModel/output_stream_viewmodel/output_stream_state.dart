part of 'output_stream_viewmodel.dart';

// ── Sealed states ─────────────────────────────────────────────────────────────

sealed class OutputStreamState {
  const OutputStreamState();
}

class OutputStreamInitial extends OutputStreamState {
  const OutputStreamInitial();
}

class OutputStreamLoading extends OutputStreamState {
  const OutputStreamLoading();
}

class OutputStreamError extends OutputStreamState {
  final String message;
  const OutputStreamError({required this.message});
}

class OutputStreamLoaded extends OutputStreamState {
  final Aes67Config stream;
  final bool isAdvancedExpanded;

  const OutputStreamLoaded({
    required this.stream,
    this.isAdvancedExpanded = false,
  });

  // Convenience getters from stream
  String get name => stream.name;
  int get channelCount => stream.channels;
  List<Aes67ChannelConfig> get channelConfigs => stream.channelConfigs;
  String get sessionId => stream.streamOrAdvertisement;
  String get ipAddress => stream.ipAddress;
  String get bitDepth => stream.bitDepth;
  String get sampleRate => stream.sampleRate;
  String get packetTime => stream.packetTime;

  OutputStreamLoaded copyWith({
    Aes67Config? stream,
    bool? isAdvancedExpanded,
  }) {
    return OutputStreamLoaded(
      stream: stream ?? this.stream,
      isAdvancedExpanded: isAdvancedExpanded ?? this.isAdvancedExpanded,
    );
  }
}
