import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/processing/config_zones_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/constants/assets_constants.dart';
import '../../../../processing_block/view/processing_chain_view.dart';
import '../../../view_models/zone_control_view_model.dart';
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
  late final TextEditingController volumeController;

  @override
  void initState() {
    volumeController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    volumeController.dispose();
    super.dispose();
  }

  /// Keep the text field in sync with cubit state.
  void _syncVolumeText(double gain) {
    final String formatted = gain.toStringAsFixed(1);
    if (volumeController.text != formatted) {
      volumeController.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ZoneControlViewModel>(
      key: ValueKey<String>('subzone_ctrl_${widget.subZone.id}'),
      create: (_) => ZoneControlViewModel(zoneId: widget.subZone.id),
      child: Builder(
        builder: (BuildContext context) {
          return BlocBuilder<ZoneControlViewModel, ZoneControlState>(
            builder: (BuildContext context, ZoneControlState zoneState) {
              _syncVolumeText(zoneState.gain);
              final ZoneControlViewModel vm = context.read<ZoneControlViewModel>();

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
                              vm.setGain(newVolume);
                            },
                            onIncrement: () {
                              vm.incrementGain();
                            },
                            onDecrement: () {
                              vm.decrementGain();
                            },
                          ),

                          IconButton(
                            onPressed: () {
                              vm.toggleMute();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              zoneState.muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
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
                      meterId: vm.processingBlock?.id,
                    ),

                    if (vm.getCircuitsInSubZone(subZoneId: widget.subZone.id).isNotEmpty) ...<Widget>[
                      CircuitExpandableSection(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        title: 'Circuits',
                        children:
                            vm
                                .getCircuitsInSubZone(subZoneId: widget.subZone.id)
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
            },
          );
        },
      ),
    );
  }
}
