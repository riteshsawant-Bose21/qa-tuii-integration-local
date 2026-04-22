import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/projects/view_model/audio_message_sync/audio_message_sync_view model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'message_player_widget.dart';

/// Animated equalizer bars shown when a track is playing.
class _EqualizerIcon extends StatefulWidget {
  final Color color;
  const _EqualizerIcon({required this.color});

  @override
  State<_EqualizerIcon> createState() => _EqualizerIconState();
}

class _EqualizerIconState extends State<_EqualizerIcon> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const List<Duration> _durations = <Duration>[
    Duration(milliseconds: 400),
    Duration(milliseconds: 600),
    Duration(milliseconds: 500),
    Duration(milliseconds: 700),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List<AnimationController>.generate(4, (int i) {
      return AnimationController(vsync: this, duration: _durations[i])..repeat(reverse: true);
    });
    _animations =
        _controllers.map((AnimationController c) {
          return Tween<double>(begin: 4, end: 18).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
        }).toList();
  }

  @override
  void dispose() {
    for (final AnimationController c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: AnimatedBuilder(
        animation: Listenable.merge(_controllers),
        builder: (BuildContext context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(4, (int i) {
              return Container(
                width: 4,
                height: _animations[i].value,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

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
  Timer? _progressTimer;
  int _elapsedSeconds = 0;
  String? _loadingTrackId;

  void _startProgressTimer(String trackId) {
    _stopProgressTimer();
    _elapsedSeconds = 0;
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final MessageTrack? playing = widget.playerData.currentlyPlayingTrack;
      final int? totalSeconds = playing?.mediaFile?.length?.inSeconds;
      if (totalSeconds != null && _elapsedSeconds >= totalSeconds) {
        widget.onStopPlayback();
        _stopProgressTimer();
        setState(() {});
        return;
      }
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _elapsedSeconds = 0;
  }

  @override
  void dispose() {
    _stopProgressTimer();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final int m = totalSeconds ~/ 60;
    final int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

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
          maxHeight: MediaQuery.of(context).size.height * 0.5,
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
                  FusionAppText(text: widget.playerData.title.toUpperCase(), style: context.textTheme.b3Regular),
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
                  final Color textColor = isPlaying ? context.colorScheme.textPrimary : context.colorScheme.textPrimary;

                  final bool isLoading = _loadingTrackId == track.id;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPlaying ? context.colorScheme.elevation3 : context.colorScheme.elevation1,
                        shape: BoxShape.circle,
                      ),
                      child:
                          isLoading
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(context.colorScheme.primary),
                                ),
                              )
                              : isPlaying
                              ? _EqualizerIcon(color: context.colorScheme.primary)
                              : Icon(Icons.play_arrow_rounded, color: textColor),
                    ),
                    title: FusionAppText(text: track.title, style: context.textTheme.l1Regular),
                    onTap: () {
                      if (isPlaying) {
                        widget.onStopPlayback();
                        _stopProgressTimer();
                        setState(() {});
                      } else if (_loadingTrackId == null) {
                        /// Trigger playback via API and show loading state until response is received
                        setState(() => _loadingTrackId = track.id);
                        serviceLocator<AudioMessageSyncViewModel>().triggerMessage(triggerId: track.id).then((ResponseCallback<bool> response) {
                          if (!mounted) return;
                          if (!response.success) {
                            setState(() => _loadingTrackId = null);
                            FusionToast.error(context, message: 'Failed to play message');
                          } else {
                            widget.onPlayTrack(track.id);
                            _startProgressTimer(track.id);
                            setState(() => _loadingTrackId = null);
                          }
                        });
                      }
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(Icons.music_note_rounded, size: 16, color: context.colorScheme.iconWhite),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FusionAppText(
                                text: playingTrack.title,
                                style: context.textTheme.l1Regular,
                                maxLine: 1,
                                textOverflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Builder(
                          builder: (BuildContext context) {
                            final Duration? totalDuration = playingTrack.mediaFile?.length;
                            final int totalSeconds = totalDuration?.inSeconds ?? 0;
                            final double progress = totalSeconds > 0 ? (_elapsedSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
                            final String elapsed = _formatDuration(_elapsedSeconds);
                            final String total = totalSeconds > 0 ? _formatDuration(totalSeconds) : '--:--';

                            return Column(
                              children: <Widget>[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: totalSeconds > 0 ? progress : null,
                                    minHeight: 4,
                                    backgroundColor: context.colorScheme.elevation3,
                                    valueColor: AlwaysStoppedAnimation<Color>(context.colorScheme.primary),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    FusionAppText(text: elapsed, style: context.textTheme.l2Regular.withColor(context.colorScheme.textSecondary)),
                                    FusionAppText(text: total, style: context.textTheme.l2Regular.withColor(context.colorScheme.textSecondary)),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
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
