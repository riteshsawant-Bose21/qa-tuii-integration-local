import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/message/message_pages_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/message/message_players_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/message/message_vc_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Main Message tab — three-column layout mirroring [SnapshotsScenesPanel].
class MessagePanel extends StatelessWidget {
  const MessagePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) return const SizedBox.shrink();

        return Container(
          color: context.colorScheme.elevation1,
          padding: const EdgeInsets.all(16),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// Left: MESSAGE PLAYERS (top) + MESSAGE LIST (bottom)
              Expanded(flex: 3, child: MessagePlayersPanel()),
              SizedBox(width: 12),

              /// Middle: PAGES
              Expanded(flex: 2, child: MessagePagesPanel()),
              SizedBox(width: 12),

              /// Right: VIRTUAL CONTROLLER
              Expanded(flex: 4, child: MessageVcPanel()),
            ],
          ),
        );
      },
    );
  }
}
