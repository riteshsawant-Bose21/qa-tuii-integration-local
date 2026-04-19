import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/message_player/message_player_card.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'message_player_dialog.dart';

// --- 1. Data Models ---

/// Represents a single message track inside a player.
class MessageTrack {
  final String id;
  final String title;
  final MediaFileModel? mediaFile;
  bool isPlaying;

  MessageTrack({
    required this.id,
    required this.title,
    this.mediaFile,
    this.isPlaying = false,
  });
}

/// Represents a group of messages (a "Message Player").
class MessagePlayerTestData {
  final String id;
  final String title;
  final List<MessageTrack> messages;

  MessagePlayerTestData({
    required this.id,
    required this.title,
    required this.messages,
  });

  /// Helper to check if any track in this player is currently active.
  bool get isAnyTrackPlaying => messages.any((MessageTrack track) => track.isPlaying);

  /// Helper to get the currently playing track, if any.
  MessageTrack? get currentlyPlayingTrack {
    try {
      return messages.firstWhere((MessageTrack track) => track.isPlaying);
    } catch (e) {
      return null;
    }
  }
}

List<MessagePlayerTestData> buildMessagePlayerData() {
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  // Get all message player sources via the service layer
  final List<Source> messagePlayers = projectViewModel.getAllMessagePlayerSources();

  return messagePlayers.map((Source source) {
    final List<MessageModel> messages = projectViewModel.getMessagesForSource(source.id);

    final List<MessageTrack> tracks =
        messages.map((MessageModel message) {
          final MediaFileModel? mediaFile = projectViewModel.getMediaFileForMessage(message.id);
          return MessageTrack(
            id: message.id,
            title: message.name,
            mediaFile: mediaFile,
          );
        }).toList();

    return MessagePlayerTestData(
      id: source.id,
      title: source.name,
      messages: tracks,
    );
  }).toList();
}

class MessagePlayerWidget extends StatefulWidget {
  const MessagePlayerWidget({super.key});

  @override
  State<MessagePlayerWidget> createState() => _MessagePlayerWidgetState();
}

class _MessagePlayerWidgetState extends State<MessagePlayerWidget> {
  late List<MessagePlayerTestData> players;

  @override
  void initState() {
    super.initState();
    players = buildMessagePlayerData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: context.colorScheme.elevation1,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: context.colorScheme.elevation2),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        children: <Widget>[
          DashboardSectionHeader(
            title: "MESSAGE PLAYERS",
            showViewAll: false,
            onViewAll: () {},
          ),
          Expanded(
            child:
                players.isEmpty
                    ? const Center(child: Text('No message players configured'))
                    : ListView.separated(
                      itemCount: players.length,
                      separatorBuilder:
                          (BuildContext context, int index) => Divider(
                            thickness: 1,
                            color: context.colorScheme.strokeLight,
                          ),
                      itemBuilder: (BuildContext context, int index) {
                        final MessagePlayerTestData player = players[index];
                        return MessagePlayerCard(
                          player: player,
                          onShowDialog: (MessagePlayerTestData player) => _showDialog(player, context),
                          onStopPlayback: _stopAllPlayback,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  /// Handles stopping playback globally across all players
  void _stopAllPlayback() {
    setState(() {
      for (final MessagePlayerTestData player in players) {
        for (final MessageTrack message in player.messages) {
          message.isPlaying = false;
        }
      }
    });
  }

  /// Handles playing a specific track and ensuring only one plays at a time
  void _playTrack(String playerId, String trackId) {
    setState(() {
      _stopAllPlayback();
      final MessagePlayerTestData player = players.firstWhere((MessagePlayerTestData p) => p.id == playerId);
      final MessageTrack track = player.messages.firstWhere((MessageTrack t) => t.id == trackId);
      track.isPlaying = true;
    });
  }

  void _showDialog(MessagePlayerTestData playerData, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MessagePlayerDialog(
          playerData: playerData,
          onStopPlayback: _stopAllPlayback,
          onPlayTrack: (String trackId) => _playTrack(playerData.id, trackId),
        );
      },
    ).then((_) {
      setState(() {});
    });
  }
}
