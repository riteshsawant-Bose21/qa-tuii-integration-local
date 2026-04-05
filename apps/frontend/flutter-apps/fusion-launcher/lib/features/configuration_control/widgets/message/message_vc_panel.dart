import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Right panel — VIRTUAL CONTROLLER (message tab).
///
/// Shows the active page title and lists the messages for that player.
/// Each message item has a chevron arrow matching the design reference.
class MessageVcPanel extends StatelessWidget {
  const MessageVcPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const PanelSectionHeader(title: 'VIRTUAL CONTROLLER'),
              Expanded(child: _buildContent(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ConfigControlLoaded state) {
    // Resolve active player from selected page
    final String? activePlayerId = state.selectedMessagePageId;
    final Source? activePlayer = activePlayerId != null ? state.messagePlayers.where((Source s) => s.id == activePlayerId).cast<Source?>().firstOrNull : null;

    final List<MessageModel> messages = activePlayer != null ? (state.messagesPerPlayer[activePlayer.id] ?? <MessageModel>[]) : <MessageModel>[];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Title header ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: FusionAppText(
                  text: activePlayer?.name ?? 'Message Player',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),

              // ── Message list ──────────────────────────────────────────
              if (activePlayer == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: FusionAppText(
                    text: 'Select a page to view messages',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.textSecondary,
                    ),
                  ),
                )
              else if (messages.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: FusionAppText(
                    text: 'No messages configured for this player',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.textSecondary,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final MessageModel message = messages[index];
                      final bool isSelected = (state.selectedMessageIdsPerPlayer[activePlayer.id] ?? <String>{}).contains(message.id);
                      return _MessageVcItem(
                        message: message,
                        isSelected: isSelected,
                        onTap: () => context.read<ConfigurationControlViewmodel>().toggleMessageSelection(activePlayer.id, message.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Message VC row ───────────────────────────────────────────────────────────

class _MessageVcItem extends StatelessWidget {
  final MessageModel message;
  final bool isSelected;
  final VoidCallback onTap;

  const _MessageVcItem({
    required this.message,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? context.colorScheme.elevation3 : context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? context.colorScheme.strokeDark : context.colorScheme.strokeLight,
            width: 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: message.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: context.colorScheme.iconDefault,
            ),
          ],
        ),
      ),
    );
  }
}
