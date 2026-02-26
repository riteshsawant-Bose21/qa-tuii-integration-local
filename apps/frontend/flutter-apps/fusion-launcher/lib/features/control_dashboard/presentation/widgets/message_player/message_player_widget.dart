import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/message_player/message_player_card.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'message_player_dialog.dart';

// --- 1. Data Models ---

/// Represents a single message track inside a player.
class MessageTrack {
  final String id;
  final String title;
  bool isPlaying;

  MessageTrack({
    required this.id,
    required this.title,
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

// --- 2. Sample Data Generator ---

List<MessagePlayerTestData> generateSampleData() {
  return <MessagePlayerTestData>[
    MessagePlayerTestData(
      id: 'p1',
      title: 'Message Player 1',
      messages: <MessageTrack>[
        MessageTrack(id: 'm1_1', title: 'Message 1'),
        MessageTrack(id: 'm1_2', title: 'Message 2'),
        MessageTrack(id: 'm1_3', title: 'Message 3'),
        // Matching Image 5 & 6: This track is actively playing
        MessageTrack(id: 'm1_4', title: 'Morning ...', isPlaying: true),
        MessageTrack(id: 'm1_5', title: 'Message 5'),
        MessageTrack(id: 'm1_6', title: 'Message 6'),
        MessageTrack(id: 'm1_7', title: 'Message 7'),
        MessageTrack(id: 'm1_8', title: 'Message 8'),
        MessageTrack(id: 'm1_9', title: 'Message 9'),
      ],
    ),
    MessagePlayerTestData(
      id: 'p2',
      title: 'Message Player 2',
      messages: List<MessageTrack>.generate(5, (int index) => MessageTrack(id: 'm2_$index', title: 'Message ${index + 1}')),
    ),
    MessagePlayerTestData(
      id: 'p3',
      title: 'Message Player 3',
      messages: List<MessageTrack>.generate(3, (int index) => MessageTrack(id: 'm3_$index', title: 'Message ${index + 1}')),
    ),
    MessagePlayerTestData(
      id: 'p4',
      title: 'Message Player 4',
      messages: List<MessageTrack>.generate(6, (int index) => MessageTrack(id: 'm4_$index', title: 'Message ${index + 1}')),
    ),
    MessagePlayerTestData(
      id: 'p5',
      title: 'Message Player 5',
      messages: List<MessageTrack>.generate(4, (int index) => MessageTrack(id: 'm5_$index', title: 'Message ${index + 1}')),
    ),
  ];
}

// --- 4. Main Widget ---

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
    players = generateSampleData();
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
            child: ListView.separated(
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
      for (MessagePlayerTestData player in players) {
        for (MessageTrack message in player.messages) {
          message.isPlaying = false;
        }
      }
    });
  }

  /// Handles playing a specific track and ensuring only one plays at a time
  void _playTrack(String playerId, String trackId) {
    setState(() {
      _stopAllPlayback(); // Stop others first
      // Find the player and track to play
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
      // Ensure main widget rebuilds when dialog closes to reflect changes
      setState(() {});
    });
  }
}
