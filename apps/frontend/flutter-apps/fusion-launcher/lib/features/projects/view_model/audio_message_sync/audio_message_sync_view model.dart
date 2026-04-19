import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/pava/pava_message_model.dart';

import 'audio_messge_sync_state.dart';

class AudioMessageSyncViewModel extends Cubit<AudioMessageSyncState> {
  final MessageSyncService messageSyncService;

  AudioMessageSyncViewModel({required this.messageSyncService}) : super(AudioMessageSyncInitial());

  String get vip => serviceLocator<ProjectViewModel>().virtualIP ?? "";

  Future<ResponseCallback<bool>> syncPendingAudioMessages() async {
    try {
      /// Get all media files
      final List<MediaFileModel> allMediaFiles = serviceLocator<ProjectViewModel>().getAllMediaFiles();

      if (allMediaFiles.isEmpty) {
        return ResponseCallback<bool>.success(true);
      }

      /// fetch messages already on the fusion server
      final ResponseCallback<List<PavaMessageModel>> getResponse = await messageSyncService.getMessages(vip: vip);

      if (!getResponse.success) {
        return ResponseCallback<bool>.failure(getResponse.message);
      }

      final List<PavaMessageModel> serverMessages = getResponse.data ?? <PavaMessageModel>[];

      /// Create a set of display names of messages already on the server for quick lookup
      final Set<String> syncedMediaIds = serverMessages.map((PavaMessageModel m) => m.displayName).toSet();

      ///  Find all media files that are NOT yet synced
      final List<MediaFileModel> pendingFiles = allMediaFiles.where((MediaFileModel m) => !syncedMediaIds.contains(m.id)).toList();

      /// Upload each pending file one by one
      for (final MediaFileModel mediaFile in pendingFiles) {
        File audioFile;
        try {
          audioFile = await serviceLocator<ProjectViewModel>().getMediaFileFromProject(mediaId: mediaFile.id);
        } catch (e) {
          debugPrint('syncPendingAudioMessages: could not get file for ${mediaFile.id}: $e');
          continue;
        }

        final ResponseCallback<PavaMessageModel> uploadResponse = await messageSyncService.uploadMessage(
          vip: vip,
          audioFile: audioFile,
          displayName: mediaFile.id,
        );

        if (!uploadResponse.success || uploadResponse.data == null) {
          return ResponseCallback<bool>.failure(uploadResponse.message);
        }

        /// Update the MediaFileModel with the server-assigned id as triggerId
        final MediaFileModel updatedMediaFile = mediaFile.copyWith(triggerId: uploadResponse.data!.id);
        await serviceLocator<ProjectViewModel>().updateMediaFile(mediaFile: updatedMediaFile);
      }

      return ResponseCallback<bool>.success(true);
    } catch (e) {
      return ResponseCallback<bool>.failure('Failed to sync pending audio messages: $e');
    }
  }

  /// Trigger a message by its triggerId (which should be the server-assigned id after upload)
  Future<ResponseCallback<bool>> triggerMessage({required String triggerId}) async {
    try {
      return await messageSyncService.triggerMessage(vip: vip, triggerId: triggerId);
    } catch (e) {
      return ResponseCallback<bool>.failure('Failed to trigger message: $e');
    }
  }
}
