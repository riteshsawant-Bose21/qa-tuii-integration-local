import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/processing_blocks/widgets/disabled_widget_wrapper.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'block_header.dart';

class PBBlockLayout extends StatelessWidget {
  const PBBlockLayout({
    super.key,
    required this.pb,
    this.actions,
    required this.body,
    required this.bypassed,
    required this.onBypassChanged,
  });
  final ProcessingBlockModel pb;
  final List<Widget>? actions;
  final Widget body;
  final bool bypassed;
  final ValueChanged<bool> onBypassChanged;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        BlockHeader(
          pb: pb,
          actions: Row(
            children: <Widget>[
              ...?actions,
              ...<Widget>[
                const SizedBox(width: 10),
                const FusionAppText(text: "BYPASS"),
                const SizedBox(width: 10),
                FusionSwitch(
                  inactiveTrackColor: context.colorScheme.elevation1,
                  value: bypassed,
                  onChanged: onBypassChanged,
                  height: 30,
                  width: 50,
                ),
              ],
            ],
          ),
        ),

        Expanded(child: DisabledWidgetWrapper(isDisabled: bypassed, child: body)),
      ],
    );
  }
}
