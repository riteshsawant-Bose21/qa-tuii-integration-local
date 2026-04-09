import 'package:flutter/material.dart';
import 'package:fusion_app/features/message_player/widgets/active_message_item.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_lib/fusion_lib.dart';

class MessagePlayerViewItem extends StatelessWidget {
  final String title;
  final bool showActiveCard;
  final Function? onTap;

  const MessagePlayerViewItem({super.key,
    required this.title,
     this.onTap,
    this.showActiveCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: (){
            onTap!();
          },
          child: Container(
            padding:  EdgeInsets.only(left: 16,right: 16, top: 20,bottom: showActiveCard ? 16:8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.b2Regular.copyWith(
                      fontWeight: FontWeight.w400,
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  showActiveCard ? Icons.keyboard_arrow_up : Icons.chevron_right,
                  color: context.colorScheme.iconDefault,
                )
              ],
            ),
          ),
        ),

        if (showActiveCard) ...[
          const ActiveMessageCard(),
        ],

        const SizedBox(height: 12),
        CommonDivider()
      ],
    );
  }
}