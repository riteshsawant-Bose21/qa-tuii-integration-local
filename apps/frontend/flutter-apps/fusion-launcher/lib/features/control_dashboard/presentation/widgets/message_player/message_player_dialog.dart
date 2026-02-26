import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'message_player_widget.dart';

class MessagePlayerDialog extends StatefulWidget {
  final MessagePlayerTestData playerData;
  final VoidCallback onStopPlayback;
  final Function(String trackId) onPlayTrack;

  const MessagePlayerDialog({
    super.key,
    required this.playerData,
    required this.onStopPlayback,
    required this.onPlayTrack,
  });

  @override
  State<MessagePlayerDialog> createState() => _MessagePlayerDialogState();
}

class _MessagePlayerDialogState extends State<MessagePlayerDialog> {
  @override
  Widget build(BuildContext context) {
    final MessageTrack? playingTrack = widget.playerData.currentlyPlayingTrack;
    final bool isAnythingPlaying = playingTrack != null;

    return Dialog(
      backgroundColor: context.colorScheme.elevation2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          // Max height to prevent overflowing screen on long lists
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 300,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FusionAppText(
                    text: widget.playerData.title.toUpperCase(),
                    style: context.textTheme.labelMedium!.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: context.colorScheme.iconWhite,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),

            // --- Message List ---
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.playerData.messages.length,
                separatorBuilder:
                    (BuildContext context, int index) => Divider(
                      height: 1,
                      color: context.colorScheme.strokeLight,
                    ),
                itemBuilder: (BuildContext context, int index) {
                  final MessageTrack track = widget.playerData.messages[index];
                  final bool isPlaying = track.isPlaying;
                  final Color textColor = isPlaying ? context.colorScheme.primary : context.colorScheme.textPrimary;
                  final IconData icon = isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPlaying ? context.colorScheme.elevation3 : context.colorScheme.elevation1,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: textColor),
                    ),
                    title: FusionAppText(
                      text: track.title,
                      style: context.textTheme.bodyMedium!.copyWith(
                        color: textColor,
                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      if (isPlaying) {
                        widget.onStopPlayback();
                      } else {
                        widget.onPlayTrack(track.id);
                      }
                      // Rebuild dialog to reflect new track states and show/hide bottom player
                      setState(() {});
                    },
                  );
                },
              ),
            ),

            // --- Bottom Floating Player (if active) ---
            if (isAnythingPlaying)
              Container(
                margin: const EdgeInsets.all(16),
                child: FusionContainer(
                  raised: true,
                  borderRadius: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(left: 20, right: 8),
                      title: FusionAppText(
                        text: playingTrack.title,
                        style: context.textTheme.labelMedium!.copyWith(color: context.colorScheme.primary, fontWeight: FontWeight.bold),
                        maxLine: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                      subtitle: FusionAppText(
                        text: "Now playing",
                        style: context.textTheme.labelMedium!.copyWith(color: context.colorScheme.textSecondary, fontSize: 12),
                      ),
                      trailing: Container(
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(30)),
                        child: IconButton(
                          icon: Icon(Icons.stop_rounded, color: context.colorScheme.iconWhite),
                          onPressed: () {
                            widget.onStopPlayback();
                            // Rebuild dialog to remove this bottom player
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!isAnythingPlaying) const SizedBox(height: 16), // Bottom padding if no player
          ],
        ),
      ),
    );
  }
}
