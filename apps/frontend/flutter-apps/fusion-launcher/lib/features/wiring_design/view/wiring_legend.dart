import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/view/port_connection/port_connection_overlay.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas/view/painters/elements/wiring/connection_color_util.dart';

class WiringLegend extends StatelessWidget {
  const WiringLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final List<({Color color, String label})> legendItems = <({Color color, String label})>[
      (
        color: ConnectionColorUtil.red,
        label: "Analog Connections",
      ),
      (
        color: ConnectionColorUtil.blue,
        label: "Digital Connections",
      ),
      (
        color: ConnectionColorUtil.green,
        label: "Ethernet Connections",
      ),
      (
        color: ConnectionColorUtil.gray,
        label: "GPIO Connections",
      ),
      (
        color: ConnectionColorUtil.orange,
        label: "Speaker Connections",
      ),
    ];
    return Column(
      children: <Widget>[
        FusionFlatContainer(
          semanticsId: "wiring_legend_container",
          width: 200,
          child: FusionExpansionPanel(
            content: Column(
              spacing: 10,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 10),
                for (({Color color, String label}) item in legendItems)
                  Row(
                    children: <Widget>[
                      Container(
                        width: 30,
                        height: 5,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      const SizedBox(width: 10),
                      FusionAppText(text: item.label, style: context.textTheme.l1Regular),
                    ],
                  ),
              ],
            ),
            titleBuilder:
                (BuildContext context, bool isExpanded) => Row(
                  children: <Widget>[
                    FusionAppText(text: "LEGEND", style: context.textTheme.l1Regular),
                    const Spacer(),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more, color: context.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
            semanticsId: 'wiring_legend',
          ),
        ),
      ],
    );
  }
}
