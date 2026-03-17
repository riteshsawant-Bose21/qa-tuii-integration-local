import 'package:flutter/material.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/processing/config_zones_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/constants/assets_constants.dart';
import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../../processing_block/view/processing_chain_view.dart';
import 'audio_meter_widget.dart';
import 'dashboard_circuit_widget.dart';
import 'exandable_section.dart';
import 'volume_control_buttons.dart';

class SubzoneDashboardContent extends StatefulWidget {
  final SubZone subZone;
  final bool isLast;

  const SubzoneDashboardContent({
    super.key,
    required this.subZone,
    this.isLast = false,
  });

  @override
  State<SubzoneDashboardContent> createState() => _SubzoneDashboardContentState();
}

class _SubzoneDashboardContentState extends State<SubzoneDashboardContent> {
  List<CircuitModel> get circuits {
    return serviceLocator<ProjectViewModel>().getCircuitsInSubZone(subZoneId: widget.subZone.id);
  }

  ProcessingBlockModel? get processingBlock {
    return serviceLocator<ProjectViewModel>().getUserFacingGainBlockForZone(zoneId: widget.subZone.id);
  }

  late final TextEditingController volumeController;

  @override
  void initState() {
    volumeController = TextEditingController(text: "10.0");
    super.initState();
  }

  @override
  void dispose() {
    volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius:
            widget.isLast
                ? const BorderRadius.only(
                  bottomLeft: Radius.circular(8.0),
                  bottomRight: Radius.circular(8.0),
                )
                : null,
      ),
      // padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: widget.subZone.name,
                    style: context.textTheme.labelMedium,
                  ),
                ),

                VolumeControlButtons(
                  volumeController: volumeController,
                  onVolumeChanged: (double newVolume) {
                    if (newVolume < -60) {
                      newVolume = -60.0;
                    } else if (newVolume > 12) {
                      newVolume = 12.0;
                    }
                    volumeController.text = newVolume.toStringAsFixed(1);
                  },
                  onIncrement: () {
                    double currentVolume = double.tryParse(volumeController.text) ?? 0.0;

                    currentVolume += 1.0;
                    if (currentVolume > 12.0) {
                      currentVolume = 12.0;
                    }
                    volumeController.text = currentVolume.toStringAsFixed(1);
                  },
                  onDecrement: () {
                    double currentVolume = double.tryParse(volumeController.text) ?? 0.0;

                    currentVolume -= 1.0;
                    if (currentVolume < -60.0) {
                      currentVolume = -60.0;
                    }

                    volumeController.text = currentVolume.toStringAsFixed(1);
                  },
                ),

                // Fix 1: Volume Icon
                IconButton(
                  onPressed: () {
                    serviceLocator<ProjectViewModel>().updateSubZone(
                      subZone: widget.subZone.copyWith(
                        muted: !widget.subZone.muted,
                      ),
                    );
                  },
                  padding: EdgeInsets.zero, // Removes internal padding
                  constraints: const BoxConstraints(), // Removes 48px limit
                  icon: Icon(
                    widget.subZone.muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                    size: 16,
                    color: context.colorScheme.iconWhite,
                  ),
                ),

                SemanticHelper.container(
                  testId: SemanticHelper.createTestId(
                    SemanticTypes.button,
                    FusionTestKeys.instance.zoneheaderprocessingbutton,
                  ),
                  child: InkWell(
                    onTap: () {
                      ProcessingChainView.showForSubzone(
                        context,
                        widget.subZone,
                      );
                    },
                    child: FusionImage.asset(
                      Assets.processingBlocksFilledIcon,
                      width: 24,
                      height: 24,
                      assetColor: context.colorScheme.primaryWhite,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          AudioMeterContainer(
            meterId: processingBlock?.id,
          ),

          if (circuits.isNotEmpty) ...<Widget>[
            CircuitExpandableSection(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              title: 'Circuits',
              children:
                  circuits
                      .map(
                        (CircuitModel circuit) => DashboardCircuitWidget(
                          circuit: circuit,
                        ),
                      )
                      .toList(),
            ),
          ],

          SizedBox(
            height: widget.isLast ? 10 : 5,
          ),

          if (!widget.isLast)
            Divider(
              color: context.colorScheme.elevation2,
              thickness: 1,
            ),
        ],
      ),
    );
  }
}
