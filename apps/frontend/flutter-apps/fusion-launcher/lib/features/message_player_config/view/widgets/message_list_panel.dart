import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/message_player_config/viewmodel/message_player_config_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Left panel showing the list of messages
class MessageListPanel extends StatelessWidget {
  const MessageListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colorScheme.elevation1,
      child: Column(
        children: <Widget>[
          // Add Message button at top
          _buildAddMessageButton(context),

          // Message list
          Expanded(
            child: BlocBuilder<MessagePlayerConfigCubit, MessagePlayerConfigState>(
              builder: (BuildContext context, MessagePlayerConfigState state) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: state.messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final MessageModel message = state.messages[index];
                    final bool isSelected = message.id == state.selectedMessageId;

                    return _MessageListItem(
                      message: message,
                      isSelected: isSelected,
                      onTap: () {
                        context.read<MessagePlayerConfigCubit>().selectMessage(message.id);
                      },
                      onDelete: isSelected ? () => context.read<MessagePlayerConfigCubit>().deleteSelectedMessage() : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMessageButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: NeumorphicButton(
        semanticId: 'add_message_panel',
        onTap: () {
          context.read<MessagePlayerConfigCubit>().addMessage();
        },
        height: 42,
        borderRadius: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}

class _MessageListItem extends StatelessWidget {
  final MessageModel message;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _MessageListItem({
    required this.message,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(
          SemanticTypes.button,
          'message_item_${message.id}',
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? context.colorScheme.elevation3 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? Border.all(color: context.colorScheme.strokeLight) : null,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: message.name,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLine: 1,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected && onDelete != null)
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: context.colorScheme.iconDefault,
                        ),
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
