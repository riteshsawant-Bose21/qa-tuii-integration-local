import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../dashboard/presentation/widgets/project_card.dart';

class ReplaceSpeakersWarningDialog extends StatelessWidget {
  final String listeningAreaName, existingSpeakerName, currentSpeakerName;
  const ReplaceSpeakersWarningDialog({super.key, required this.listeningAreaName, required this.existingSpeakerName, required this.currentSpeakerName});

  static Future<bool?> show(
    BuildContext context, {
    required String listeningAreaName,
    required String existingSpeakerName,
    required String currentSpeakerName,
  }) {
    return Navigator.of(context).push(
      AnimatedBlurDialogRoute<bool>(
        builder: (BuildContext context) {
          return Material(
            color: Colors.transparent,
            child: ReplaceSpeakersWarningDialog(
              listeningAreaName: listeningAreaName,
              existingSpeakerName: existingSpeakerName,
              currentSpeakerName: currentSpeakerName,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.colorScheme.surface,
        border: Border.all(color: context.colorScheme.onSurface.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  LucideIcons.circleAlert200,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FusionAppText(
                    text: "Replace Speakers",
                    style: context.textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            FusionAppText(
              text:
                  "The listening area '$listeningAreaName' currently has \"$existingSpeakerName\" speakers. Adding a different speaker will remove the existing ones and add \"$currentSpeakerName\".",

              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                SemanticHelper.button(
                  testId: SemanticHelper.createTestId(SemanticTypes.button, "cancel_replace_speakers_button"),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FusionAppText(
                          text: "Cancel",
                          style: context.textTheme.labelLarge?.copyWith(
                            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.container, "replace_speakers_button"),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FusionAppText(
                          text: "Replace",
                          style: context.textTheme.labelLarge?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
