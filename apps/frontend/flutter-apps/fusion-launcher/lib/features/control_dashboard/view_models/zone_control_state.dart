part of 'zone_control_view_model.dart';

class ZoneControlState {
  /// Current gain value (dB). Defaults to 0.0.
  final double gain;

  /// Whether the zone is muted.
  final bool muted;

  /// The processing block id used for server communication.
  final String? blockId;

  /// True while the initial fetch is in progress.
  final bool isLoading;

  /// Non-null when a fetch or update error occurred.
  final String? error;

  const ZoneControlState({
    this.gain = 0.0,
    this.muted = false,
    this.blockId,
    this.isLoading = false,
    this.error,
  });

  ZoneControlState copyWith({
    double? gain,
    bool? muted,
    String? blockId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ZoneControlState(
      gain: gain ?? this.gain,
      muted: muted ?? this.muted,
      blockId: blockId ?? this.blockId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
