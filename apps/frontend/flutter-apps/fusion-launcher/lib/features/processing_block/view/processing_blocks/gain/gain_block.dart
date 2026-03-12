import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_textfield.dart';
import 'package:fusion_launcher/features/processing_block/viewmodel/algorithm_data_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import '../../../../zone_functions/widgets/neumorphic_audio_toggle_button.dart';
import '../widgets/pb_block_layout.dart';

part '_gain_controller.dart';

class GainBlock extends StatelessWidget {
  const GainBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final AlgorithmDataViewmodel watch =
        context.watch<AlgorithmDataViewmodel>();
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        'gain_block',
      ),
      child: ProxyProvider<AlgorithmDataViewmodel, GainController>(
        key: ValueKey<String>(watch.processingBlock.id),
        create: (BuildContext context) {
          return GainController(watch);
        },
        update:
            (
              BuildContext context,
              AlgorithmDataViewmodel valueHandler,
              GainController? previous,
            ) => GainController(valueHandler),
        child: Builder(
          builder: (BuildContext context) {
            return PBBlockLayout(
              pb: context.watch<AlgorithmDataViewmodel>().processingBlock,
              onBypassChanged: context.read<GainController>().bypassGlobally,
              bypassed: context.watch<GainController>().isGloballyBypassed,
              body: Row(
                spacing: 3,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation2,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(context.mediumRadius),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,

                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: context.colorScheme.strokeLight,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(
                                width: 80,
                                // height: 25,
                                child: PBNumberTextField(
                                  semanticId: 'gain_text_field',
                                  // value: context.watch<LimiterController>().currentThreshold ?? 0,
                                  value:
                                      (context
                                                  .watch<GainController>()
                                                  .currentGainValue ??
                                              0)
                                          .toDouble(),
                                  onChanged: (num value) {
                                    context
                                        .read<GainController>()
                                        .updateGainValue(value);
                                  },
                                  min: 1,
                                  max: 96000,
                                ),
                              ),

                              const SizedBox(width: 4),
                              FusionAppText(
                                text: "dB",
                                capitalize: false,
                                style: context.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),

                        /// gain slider
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: VerticalSlider(
                              semanticId: 'gain_slider',
                              value:
                                  context
                                      .watch<GainController>()
                                      .currentGainSliderValue ??
                                  0,
                              min: -60.0,
                              max: 24.0,
                              showIntervals: true,
                              activeColor: context.colorScheme.primary,
                              onChanged: (num value) {
                                context
                                    .read<GainController>()
                                    .updateGainSliderValue(value);
                              },
                            ),
                          ),
                        ),

                        /// mute toggle
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colorScheme.elevation2,
                            border: Border(
                              top: BorderSide(
                                color: context.colorScheme.strokeLight,
                              ),
                            ),
                          ),
                          child: NeumorphicAudioToggleButton(
                            isActive:
                                context.watch<GainController>().isGainMuted,
                            backgroundColor: context.colorScheme.elevation2,
                            width: 100,
                            onTap: () {
                              final bool isCurrentlyMuted =
                                  context.read<GainController>().isGainMuted;
                              context.read<GainController>().toggleGainMute(
                                !isCurrentlyMuted,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// output meter
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation2,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(context.mediumRadius),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),

                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: context.colorScheme.strokeLight,
                              ),
                            ),
                          ),
                          child: FusionAppText(
                            text: "OUTPUT",
                            style: context.textTheme.bodyMedium,
                          ),
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: VerticalMeter(
                              semanticId: 'gain_output_meter',
                              value: -60,
                              min: -60,
                              max: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // children: <Widget>[
              //   /// Header with block name and actions
              //   ...getBlockHeader(
              //     context,
              //     context.watch<AlgorithmDataViewmodel>().processingBlock,
              //     actions: <Widget>[
              //       const FusionAppText(text: "BYPASS"),
              //       const SizedBox(width: 10),
              //       FusionSwitch(
              //         inactiveTrackColor: context.colorScheme.elevation1,
              //         value: context.watch<GainController>().isGloballyBypassed,
              //         onChanged: (bool value) {
              //           context.read<GainController>().bypassGlobally(value);
              //         },
              //         height: 30,
              //         width: 50,
              //       ),
              //     ],
              //   ),

              //   /// Main content area
              //   Padding(
              //     padding: const EdgeInsets.only(top: 50),
              //     child: DisabledWidgetWrapper(
              //       isDisabled: context.watch<GainController>().isGloballyBypassed,
              //       child:
              //     ),
              //   ),
              // ],
            );
          },
        ),
      ),
    );
  }
}
