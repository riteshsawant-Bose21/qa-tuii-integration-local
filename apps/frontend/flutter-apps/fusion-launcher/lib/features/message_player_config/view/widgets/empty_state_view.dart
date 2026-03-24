import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/features/message_player_config/viewmodel/message_player_config_cubit.dart';
import 'package:fusion_lib/constants/semantics/features/message_player/messageplayerKeys.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/constants/assets_constants.dart';

/// Empty state view shown when no messages exist
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.messageplayerconfigemtystate),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            /// Message Player icon
            SvgPicture.asset(
              semanticsLabel: FusionTestKeys.instance.messageplayerconfigemtystateicon,
              Assets.messagePlayerConfig,
              width: 48,
              height: 48,
              colorFilter: ColorFilter.mode(
                context.colorScheme.iconWhite,
                BlendMode.srcIn,
              ),
            ),

            const SizedBox(height: 24),

            FusionAppText(
              semanticId: FusionTestKeys.instance.messageplayerconfigemtystatetext,
              text: 'Configure Message Player',
              style: context.textTheme.b3SemiBold,
            ),

            const SizedBox(height: 8),

            FusionAppText(
              semanticId: FusionTestKeys.instance.messageplayerconfigemtystatedesc,
              text: 'Start configuring the message player\nby adding new messages.',
              style: context.textTheme.l2Regular.withColor(context.colorScheme.textBody),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            /// Add Message button
            NeumorphicButton(
              semanticId: FusionTestKeys.instance.messageplayerconfigemtystatebutton,
              onTap: () {
                context.read<MessagePlayerConfigCubit>().addMessage();
              },
              width: 179,
              height: 32,
              borderRadius: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FusionIcon.icon(
                    Icons.add,
                    size: 18,
                    color: context.colorScheme.iconWhite,
                  ),
                  const SizedBox(width: 8),
                  FusionAppText(text: 'Add Message', style: context.textTheme.l1Medium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
