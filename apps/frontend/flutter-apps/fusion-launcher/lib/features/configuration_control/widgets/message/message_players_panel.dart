import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Left column: MESSAGE PLAYERS (checkboxes, top) + MESSAGE LIST (bottom).
///
/// Mirrors the SCENES / SNAPSHOT PAGE structure from [ScenesListPanel].
class MessagePlayersPanel extends StatelessWidget {
  const MessagePlayersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) return const SizedBox.shrink();

        return Column(
          children: <Widget>[
            Expanded(child: _MessagePlayersSection(state: state)),
            const SizedBox(height: 12),
            Expanded(child: _MessageListSection(state: state)),
          ],
        );
      },
    );
  }
}

// ─── MESSAGE PLAYERS section ──────────────────────────────────────────────────

class _MessagePlayersSection extends StatelessWidget {
  final ConfigControlLoaded state;
  const _MessagePlayersSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.strokeLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PanelSectionHeader(title: 'MESSAGE PLAYERS'),
          Expanded(
            child:
                state.messagePlayers.isEmpty
                    ? Center(
                      child: FusionAppText(
                        text: 'No message players available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.textSecondary,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.messagePlayers.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Source player = state.messagePlayers[index];
                        final bool isChecked = state.selectedMessagePlayerIds.contains(player.id);
                        return _MessagePlayerItem(
                          player: player,
                          isChecked: isChecked,
                          onToggle: () => context.read<ConfigurationControlViewmodel>().toggleMessagePlayerSelection(player.id),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _MessagePlayerItem extends StatelessWidget {
  final Source player;
  final bool isChecked;
  final VoidCallback onToggle;

  const _MessagePlayerItem({
    required this.player,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _FusionCheckbox(isChecked: isChecked),
            ),
          ),
          Expanded(
            child: FusionAppText(
              text: player.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isChecked ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
                fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MESSAGE LIST section ─────────────────────────────────────────────────────

class _MessageListSection extends StatelessWidget {
  final ConfigControlLoaded state;
  const _MessageListSection({required this.state});

  @override
  Widget build(BuildContext context) {
    // Only show message lists for checked players
    final List<Source> activePlayers = state.messagePlayers.where((Source s) => state.selectedMessagePlayerIds.contains(s.id)).toList();

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.strokeLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PanelSectionHeader(title: 'MESSAGE LIST'),
          Expanded(
            child:
                activePlayers.isEmpty
                    ? Center(
                      child: FusionAppText(
                        text: 'Check a message player to see its messages',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.textSecondary,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: activePlayers.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Source player = activePlayers[index];
                        final List<MessageModel> messages = state.messagesPerPlayer[player.id] ?? <MessageModel>[];
                        final Set<String> selectedIds = state.selectedMessageIdsPerPlayer[player.id] ?? <String>{};
                        return _PlayerMessageGroup(
                          player: player,
                          messages: messages,
                          selectedMessageIds: selectedIds,
                          onToggle: (String messageId) => context.read<ConfigurationControlViewmodel>().toggleMessageSelection(player.id, messageId),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _PlayerMessageGroup extends StatelessWidget {
  final Source player;
  final List<MessageModel> messages;
  final Set<String> selectedMessageIds;
  final void Function(String messageId) onToggle;

  const _PlayerMessageGroup({
    required this.player,
    required this.messages,
    required this.selectedMessageIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Group header
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: FusionAppText(
            text: player.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colorScheme.textBody,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Message list for this player
        if (messages.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: FusionAppText(
              text: 'No messages',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
          )
        else
          ...messages.map((MessageModel msg) {
            final bool isChecked = selectedMessageIds.contains(msg.id);
            return _MessageItem(
              message: msg,
              isChecked: isChecked,
              onToggle: () => onToggle(msg.id),
            );
          }),
      ],
    );
  }
}

class _MessageItem extends StatelessWidget {
  final MessageModel message;
  final bool isChecked;
  final VoidCallback onToggle;

  const _MessageItem({
    required this.message,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _FusionCheckbox(isChecked: isChecked),
            ),
          ),
          Expanded(
            child: FusionAppText(
              text: message.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isChecked ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared checkbox widget ───────────────────────────────────────────────────

class _FusionCheckbox extends StatelessWidget {
  final bool isChecked;
  const _FusionCheckbox({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isChecked ? context.colorScheme.primaryColor : context.colorScheme.iconDefault,
          width: 1.5,
        ),
        color: isChecked ? context.colorScheme.primaryColor : Colors.transparent,
      ),
      child: isChecked ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
    );
  }
}
