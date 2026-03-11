import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final String sourceId;

  const MessagePlayerConfigDialog({
    super.key,
    required this.sourceId,
  });

  /// Show the message player configuration dialog
  static Future<void> show(
    BuildContext context, {
    required String sourceId,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return MessagePlayerConfigDialog(
          sourceId: sourceId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MessagePlayerConfigCubit>(
      create: (BuildContext context) => MessagePlayerConfigCubit()..init(sourceId: sourceId),
      child: const _MessagePlayerConfigDialogContent(),
    );
  }
}

class _MessagePlayerConfigDialogContent extends StatelessWidget {
  const _MessagePlayerConfigDialogContent();

  Future<void> _onClose(BuildContext context) async {
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
          /// Dismiss on tap outside
          GestureDetector(
            onTap: () => _onClose(context),
            child: Container(color: Colors.transparent),
          ),

          /// Dialog content
          Center(
            child: Container(
              margin: const EdgeInsets.all(24.0),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
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
                  /// Header
                  _buildHeader(context),

                  /// Main content
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

  /// Dialog header with title and close button
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.strokeLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          FusionAppText(
            text: 'MESSAGE PLAYER',
            style: context.textTheme.bodySmall?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.textPrimary,
            ),
          ),

          /// Close button
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
        /// Left panel - Message list
        const SizedBox(
          width: 260,
          child: MessageListPanel(),
        ),

        /// Divider
        Container(
          width: 1,
          color: context.colorScheme.strokeLight,
        ),

        /// Center panel - Message configuration
        const Expanded(
          flex: 2,
          child: MessageConfigPanel(),
        ),

        /// Divider
        Container(
          width: 1,
          color: context.colorScheme.strokeLight,
        ),

        /// Right panel - Zone assignment
        const SizedBox(
          width: 308,
          child: ZoneAssignmentPanel(),
        ),
      ],
    );
  }
}
