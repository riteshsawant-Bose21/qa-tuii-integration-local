class ConfigurationMediaFilesState {
  final bool isPlaying;
  final String? selectedMediaFileId;
  final Duration currentPosition;

  final bool isLoading;

  ConfigurationMediaFilesState({
    this.isPlaying = false,
    this.selectedMediaFileId,
    this.currentPosition = Duration.zero,
    this.isLoading = false,
  });

  ConfigurationMediaFilesState copyWith({
    String? selectedMediaFileId,
    bool? isPlaying,
    Duration? currentPosition,
    bool? isLoading,
    bool clearSelection = false,
  }) {
    return ConfigurationMediaFilesState(
      isPlaying: isPlaying ?? this.isPlaying,
      selectedMediaFileId: clearSelection ? null : (selectedMediaFileId ?? this.selectedMediaFileId),
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
