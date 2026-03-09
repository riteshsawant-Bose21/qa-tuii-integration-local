import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/message_player_config/viewmodel/message_player_config_cubit.dart';
import 'package:fusion_launcher/features/message_player_config/view/widgets/message_list_panel.dart';
import 'package:fusion_launcher/features/message_player_config/view/widgets/message_config_panel.dart';
import 'package:fusion_launcher/features/message_player_config/view/widgets/zone_assignment_panel.dart';
import 'package:fusion_launcher/features/message_player_config/view/widgets/empty_state_view.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Message Player Configuration Dialog
///
/// This dialog allows users to configure a message player by:
/// - Adding messages
/// - Naming messages
/// - Selecting audio files
/// - Setting gain levels
/// - Configuring repeat settings
/// - Assigning zones
class MessagePlayerConfigDialog extends StatelessWidget {
  final MessagePlayerModel? messagePlayer;
  final String? messagePlayerId;

  const MessagePlayerConfigDialog({
    super.key,
    this.messagePlayer,
    this.messagePlayerId,
  });

  /// Show the message player configuration dialog
  static Future<void> show(
    BuildContext context, {
    MessagePlayerModel? messagePlayer,
    String? messagePlayerId,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return MessagePlayerConfigDialog(
          messagePlayer: messagePlayer,
          messagePlayerId: messagePlayerId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Load message player from ProjectViewModel if ID is provided
    MessagePlayerModel? player = messagePlayer;
    if (player == null && messagePlayerId != null) {
      player = serviceLocator<ProjectViewModel>().getMessagePlayerById(messagePlayerId!);
    }

    return BlocProvider<MessagePlayerConfigCubit>(
      create: (BuildContext context) => MessagePlayerConfigCubit()..init(messagePlayer: player),
      child: const _MessagePlayerConfigDialogContent(),
    );
  }
}

class _MessagePlayerConfigDialogContent extends StatelessWidget {
  const _MessagePlayerConfigDialogContent();

  Future<void> _onClose(BuildContext context) async {
    final MessagePlayerConfigCubit cubit = context.read<MessagePlayerConfigCubit>();

    // Auto-save on close if there are messages
    if (cubit.currentMessagePlayer != null && cubit.currentMessagePlayer!.messages.isNotEmpty) {
      await cubit.saveMessagePlayer();
      if (context.mounted) {
        FusionToast.success(context, message: 'Message player saved');
      }
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,
      child: Stack(
        children: <Widget>[
          // Dismiss on tap outside
          GestureDetector(
            onTap: () => _onClose(context),
            child: Container(color: Colors.transparent),
          ),

          // Dialog content
          Center(
            child: Container(
              margin: const EdgeInsets.all(24.0),
              constraints: BoxConstraints(
                maxWidth: 900,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                border: Border.all(color: context.colorScheme.strokeLight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Header
                  _buildHeader(context),

                  // Main content
                  Expanded(
                    child: BlocBuilder<MessagePlayerConfigCubit, MessagePlayerConfigState>(
                      builder: (BuildContext context, MessagePlayerConfigState state) {
                        if (state is MessagePlayerLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (state.hasNoMessages) {
                          return const EmptyStateView();
                        }
                        return const _ConfigurationContent();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.strokeLight,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          FusionAppText(
            text: 'MESSAGE PLAYER',
            style: context.textTheme.titleSmall?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.textPrimary,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onClose(context),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  LucideIcons.x,
                  color: context.colorScheme.iconDefault,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigurationContent extends StatelessWidget {
  const _ConfigurationContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Left panel - Message list
        const SizedBox(
          width: 220,
          child: MessageListPanel(),
        ),

        // Divider
        Container(
          width: 1,
          color: context.colorScheme.strokeLight,
        ),

        // Center panel - Message configuration
        const Expanded(
          flex: 2,
          child: MessageConfigPanel(),
        ),

        // Divider
        Container(
          width: 1,
          color: context.colorScheme.strokeLight,
        ),

        // Right panel - Zone assignment
        const SizedBox(
          width: 220,
          child: ZoneAssignmentPanel(),
        ),
      ],
    );
  }
}
