import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/message_player_config/viewmodel/message_player_config_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Empty state view shown when no messages exist
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Play icon with message bubble
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(
                color: context.colorScheme.strokeLight,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(
                  LucideIcons.play,
                  size: 32,
                  color: context.colorScheme.iconDefault,
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation1,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      LucideIcons.messageSquare,
                      size: 14,
                      color: context.colorScheme.iconDefault,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          FusionAppText(
            text: 'Configure Message Player',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          FusionAppText(
            text: 'Start configuring the message player\nby adding new messages.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Add Message button
          _AddMessageButton(
            onPressed: () {
              context.read<MessagePlayerConfigCubit>().addMessage();
            },
          ),
        ],
      ),
    );
  }
}

class _AddMessageButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddMessageButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        'add_message_empty_state',
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: FusionContainer(
            raised: true,
            borderRadius: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.add,
                    size: 18,
                    color: context.colorScheme.iconWhite,
                  ),
                  const SizedBox(width: 8),
                  FusionAppText(
                    text: 'Add Message',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colorScheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
