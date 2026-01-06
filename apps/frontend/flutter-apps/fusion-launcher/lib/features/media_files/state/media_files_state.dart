class ConfigurationMediaFilesState {
  final bool isPlaying;
  final String? selectedMediaFileId;
  final Duration currentPosition;
  final bool isLoading;
  final String? errorMessage;

  ConfigurationMediaFilesState({
    this.isPlaying = false,
    this.selectedMediaFileId,
    this.currentPosition = Duration.zero,
    this.isLoading = false,
    this.errorMessage,
  });

  ConfigurationMediaFilesState copyWith({
    String? selectedMediaFileId,
    bool? isPlaying,
    Duration? currentPosition,
    bool? isLoading,
    String? errorMessage,
    bool clearSelection = false,
    bool clearError = false,
  }) {
    return ConfigurationMediaFilesState(
      isPlaying: isPlaying ?? this.isPlaying,
      selectedMediaFileId: clearSelection ? null : (selectedMediaFileId ?? this.selectedMediaFileId),
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
