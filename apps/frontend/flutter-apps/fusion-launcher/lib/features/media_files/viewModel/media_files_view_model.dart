import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fusion_launcher/features/media_files/state/media_files_state.dart';
import 'dart:io';

import 'package:fusion_launcher/features/media_files/view/configuration_media_files_pages.dart';

class MediaFilesViewModel extends Cubit<ConfigurationMediaFilesState> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  MediaFilesViewModel() : super(ConfigurationMediaFilesState()) {
    _initializeAudioPlayer();
  }

  void _initializeAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.playing) {
        emit(this.state.copyWith(isPlaying: true));
      } else if (state == PlayerState.paused || state == PlayerState.stopped) {
        emit(this.state.copyWith(isPlaying: false));
      } else if (state == PlayerState.completed) {
        _onAudioCompleted();
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      emit(state.copyWith(currentPosition: position));
    });
  }

  void _onAudioCompleted() {
    emit(state.copyWith(isPlaying: false, currentPosition: Duration.zero));
    // Auto play next
    if (state.selectedIndex != null && state.selectedIndex! < state.files.length - 1) {
      playNext();
    }
  }

  Future<void> pickFiles() async {
    try {
      emit(state.copyWith(isLoading: true));

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        final List<MediaFileModel> newFiles = <MediaFileModel>[];

        for (PlatformFile file in result.files) {
          if (file.path != null) {
            final File fileInfo = File(file.path!);
            final FileStat stat = await fileInfo.stat();

            final Duration duration = const Duration(minutes: 3, seconds: 30);

            final MediaFileModel mediaFile = MediaFileModel(
              id: DateTime.now().millisecondsSinceEpoch.toString() + file.name,
              name: file.name,
              path: file.path!,
              size: file.size,
              length: duration,
              date: DateTime.now(),
            );

            newFiles.add(mediaFile);
          }
        }

        final List<MediaFileModel> updatedFiles = <MediaFileModel>[...state.files, ...newFiles];

        emit(
          state.copyWith(
            files: updatedFiles,
            selectedIndex: state.selectedIndex ?? (updatedFiles.isNotEmpty ? 0 : null),
            isLoading: false,
          ),
        );

        if (state.selectedIndex == null && updatedFiles.isNotEmpty) {
          await selectFile(0);
        }
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> selectFile(int index) async {
    if (index < 0 || index >= state.files.length) return;

    final MediaFileModel file = state.files[index];

    await _audioPlayer.stop();
    await _audioPlayer.setSourceDeviceFile(file.path);

    emit(
      state.copyWith(
        selectedIndex: index,
        currentPosition: Duration.zero,
        isPlaying: false,
      ),
    );
  }

  Future<void> playPause() async {
    if (state.selectedFile == null) return;

    if (state.isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> playNext() async {
    if (state.selectedIndex == null) return;

    final int nextIndex = state.selectedIndex! + 1;
    if (nextIndex < state.files.length) {
      await selectFile(nextIndex);
      await _audioPlayer.resume();
    }
  }

  Future<void> playPrevious() async {
    if (state.selectedIndex == null) return;

    final int prevIndex = state.selectedIndex! - 1;
    if (prevIndex >= 0) {
      await selectFile(prevIndex);
      await _audioPlayer.resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> close() {
    _audioPlayer.dispose();
    return super.close();
  }
}
