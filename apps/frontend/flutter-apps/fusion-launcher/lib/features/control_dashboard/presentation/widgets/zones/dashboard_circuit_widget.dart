import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/assets/asset_icons.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'audio_meter_widget.dart';

class DashboardCircuitWidget extends StatelessWidget {
  final CircuitModel circuit;
  final EdgeInsetsGeometry? margin;

  const DashboardCircuitWidget({
    super.key,
    required this.circuit,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(12),
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              FusionImage.asset(
                AssetIcons.genericSpeaker,
                width: 16,
                height: 16,
                assetColor: context.colorScheme.iconDefault,
              ),
              const SizedBox(width: 8),
              Text(
                circuit.name,
                style: context.textTheme.labelSmall!.copyWith(
                  color: context.colorScheme.textSecondary,
                ),
              ),

              const Spacer(),

              InkWell(
                onTap: () {},
                child: Icon(
                  Icons.volume_up_outlined,
                  size: 16,
                  color: context.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const AudioMeterContainer(
            marginHorizontal: 0,
          ),
        ],
      ),
    );
  }
}
