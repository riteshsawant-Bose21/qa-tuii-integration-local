import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'message_player_widget.dart';

class MessagePlayerCard extends StatelessWidget {
  final MessagePlayerTestData player;
  final VoidCallback? onStopPlayback;
  final Function(MessagePlayerTestData player) onShowDialog;

  const MessagePlayerCard({
    super.key,
    required this.player,
    this.onStopPlayback,
    required this.onShowDialog,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = player.isAnyTrackPlaying;
    final MessageTrack? playingTrack = player.currentlyPlayingTrack;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: FusionAppText(
            text: player.title,
            style: context.textTheme.labelMedium!.copyWith(
              color: context.colorScheme.textPrimary,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.list_rounded,
              color: context.colorScheme.iconWhite,
            ),
            onPressed: () => onShowDialog(player),
          ),
        ),
        if (isPlaying && playingTrack != null) ...<Widget>[
          // --- Active Playing State UI (Image 5 top item) ---
          FusionContainer(
            raised: true,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FusionAppText(
                          text: playingTrack.title,
                          style: context.textTheme.bodyMedium!.copyWith(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        FusionAppText(
                          text: "Now playing",
                          style: context.textTheme.labelSmall!.copyWith(
                            color: context.colorScheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FusionContainer(
                    borderRadius: 100,
                    raised: true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colorScheme.elevation1,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.stop_rounded,
                          color: context.colorScheme.iconWhite,
                        ),
                        onPressed: () {
                          onStopPlayback?.call();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
        ],
      ],
    );
  }
}
