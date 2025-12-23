import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/media_files/state/media_files_state.dart';
import 'dart:io';

import 'package:fusion_lib/models/project_entities/media_files/media_file_model.dart';

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
    if (state.selectedMediaFileId != null) {
      playNext();
    }
  }

  List<MediaFileModel> getAllFiles() {
    return serviceLocator<ProjectViewModel>().getAllMediaFiles();
  }

  MediaFileModel? getSelectedFile() {
    if (state.selectedMediaFileId == null) return null;

    final MediaFileModel? selectedFile = serviceLocator<ProjectViewModel>().getMediaFileModelById(state.selectedMediaFileId!);

    return selectedFile;
  }

  Future<void> pickFiles() async {
    try {
      emit(state.copyWith(isLoading: true));

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null) {
        if (result.files.first.path != null) {
          final File fileInfo = File(result.files.first.path!);

          await serviceLocator<ProjectViewModel>().addMediaFile(file: fileInfo);
        }
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> selectFile(MediaFileModel mediaFileModel) async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      // Handle error if needed
    }
    try {
      final File file = await serviceLocator<ProjectViewModel>().getMediaFileFromProject(mediaId: mediaFileModel.id);
      await _audioPlayer.setSourceDeviceFile(file.path);
    } catch (e) {
      // Handle error if needed
    }

    emit(
      state.copyWith(
        selectedMediaFileId: mediaFileModel.id,
        currentPosition: Duration.zero,
        isPlaying: false,
      ),
    );
  }

  Future<void> deleteMediaFile(String mediaId) async {
    final MediaFileModel? mediaFile = serviceLocator<ProjectViewModel>().getMediaFileModelById(mediaId);
    if (mediaFile == null) return;

    if (state.selectedMediaFileId == mediaId) {
      await _audioPlayer.stop();
      emit(
        state.copyWith(
          selectedMediaFileId: null,
          currentPosition: Duration.zero,
          isPlaying: false,
        ),
      );
    }

    await serviceLocator<ProjectViewModel>().removeMediaFileById(mediaId);
  }

  Future<void> playPause() async {
    if (state.selectedMediaFileId == null) return;

    if (state.isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> playNext() async {
    if (state.selectedMediaFileId == null) return;

    final List<MediaFileModel> stateFiles = getAllFiles();
    final int currentIndex = stateFiles.indexWhere((MediaFileModel file) => file.id == state.selectedMediaFileId);
    if (currentIndex == -1) return;

    final int nextIndex = currentIndex + 1;
    if (nextIndex < stateFiles.length) {
      await selectFile(stateFiles[nextIndex]);
      await _audioPlayer.resume();
    }
  }

  Future<void> playPrevious() async {
    if (state.selectedMediaFileId == null) return;

    final List<MediaFileModel> stateFiles = getAllFiles();
    final int currentIndex = stateFiles.indexWhere((MediaFileModel file) => file.id == state.selectedMediaFileId);
    if (currentIndex == -1) return;

    final int previousIndex = currentIndex - 1;
    if (previousIndex >= 0) {
      await selectFile(stateFiles[previousIndex]);
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
