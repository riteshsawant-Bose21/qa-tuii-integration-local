import 'package:fusion_launcher/features/media_files/view/configuration_media_files_pages.dart';

class ConfigurationMediaFilesState {
  final List<MediaFileModel> files;
  final int? selectedIndex;
  final bool isPlaying;
  final Duration currentPosition;
  final bool isLoading;

  ConfigurationMediaFilesState({
    this.files = const <MediaFileModel>[],
    this.selectedIndex,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.isLoading = false,
  });

  ConfigurationMediaFilesState copyWith({
    List<MediaFileModel>? files,
    int? selectedIndex,
    bool? isPlaying,
    Duration? currentPosition,
    bool? isLoading,
    bool clearSelection = false,
  }) {
    return ConfigurationMediaFilesState(
      files: files ?? this.files,
      selectedIndex: clearSelection ? null : (selectedIndex ?? this.selectedIndex),
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  MediaFileModel? get selectedFile {
    if (selectedIndex != null && selectedIndex! < files.length) {
      return files[selectedIndex!];
    }
    return null;
  }
}
