import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/assets/asset_icons.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/processing/config_zones_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/constants/assets_constants.dart';
import '../../../../processing_block/view/processing_chain_view.dart';
import 'audio_meter_widget.dart';

class DashboardCircuitWidget extends StatelessWidget {
  final CircuitModel circuit;
  final EdgeInsetsGeometry? margin;
  final bool isZoneMuted;

  const DashboardCircuitWidget({
    super.key,
    required this.circuit,
    this.margin,
    this.isZoneMuted = false,
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
                onTap: () {
                  serviceLocator<ProjectViewModel>().updateCircuit(
                    circuit: circuit.copyWith(
                      muted: !circuit.muted,
                    ),
                  );
                },
                child: Icon(
                  circuit.muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                  size: 16,
                  color: context.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  ProcessingChainView.showForCircuit(context, circuit);
                },
                child: FusionImage.asset(
                  semanticId: FusionTestKeys.instance.zonecircuititmimg2,
                  Assets.processingBlocksFilledIcon,
                  width: 22,
                  height: 22,
                  assetColor: context.colorScheme.primaryWhite,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          AudioMeterContainer(
            marginHorizontal: 0,
            muted: circuit.muted || isZoneMuted,
          ),
        ],
      ),
    );
  }
}
