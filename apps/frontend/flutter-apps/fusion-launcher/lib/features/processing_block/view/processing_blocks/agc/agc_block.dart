import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/processing_blocks/widgets/pb_section.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_meter.dart';
import 'package:fusion_launcher/features/zone_functions/widgets/neumorphic_gain_text_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import '../../../../add_source_popup/view_model/add_source_viewmodel.dart';
import '../../../viewmodel/algorithm_data_viewmodel.dart';
import '../widgets/pb_block_layout.dart';

part '_agc_controller.dart';

const double _sectionWidth = 120.0;

class AgcBlock extends StatelessWidget {
  const AgcBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final AlgorithmDataViewmodel watch =
        context.watch<AlgorithmDataViewmodel>();

    return ProxyProvider<AlgorithmDataViewmodel, AgcController>(
      key: ValueKey<String>(watch.processingBlock.id),
      create: (BuildContext context) => AgcController(watch),
      update:
          (
            BuildContext context,
            AlgorithmDataViewmodel valueHandler,
            AgcController? previous,
          ) => AgcController(valueHandler),
      child: Builder(
        builder: (BuildContext context) {
          final ProcessingBlockModel pb =
              context.watch<AlgorithmDataViewmodel>().processingBlock;
          final AgcController controller = context.watch<AgcController>();
          return PBBlockLayout(
            pb: context.watch<AlgorithmDataViewmodel>().processingBlock,
            onBypassChanged: context.read<AgcController>().bypassGlobally,
            bypassed: controller.isGloballyBypassed,
            body: Row(
              spacing: 2,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                PBSection(
                  type: PBSectionType.left,
                  child: SizedBox(
                    width: _sectionWidth,
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: context.colorScheme.strokeLight,
                              ),
                            ),
                          ),
                          child: Center(
                            child: FusionAppText(
                              text: "THRESHOLD",
                              style: context.textTheme.labelMedium?.copyWith(
                                color: context.colorScheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: VerticalSlider(
                              value:
                                  context
                                      .watch<AgcController>()
                                      .currentThreshold,
                              max: 12,
                              min: -60,
                              onChanged:
                                  context.read<AgcController>().updateThreshold,
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: context.colorScheme.strokeLight,
                              ),
                            ),
                          ),
                          child: NeumorphicGainTextField(
                            controllerValue:
                                context.watch<AgcController>().currentThreshold,
                            maxGain: 12,
                            minGain: -60,
                            showDbSuffix: false,
                            onSubmitted:
                                context.read<AgcController>().updateThreshold,
                          ),
                        ),
                        FusionAppText(
                          text: "dBFS",
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.colorScheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(
                  color: context.colorScheme.elevation1,
                  width: 0,
                  thickness: 2,
                ),
                PBSection(
                  type: PBSectionType.middle,
                  child: SizedBox(
                    width: _sectionWidth,
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.colorScheme.elevation2,
                            border: Border(
                              bottom: BorderSide(
                                color: context.colorScheme.strokeLight,
                              ),
                            ),
                          ),
                          child: Center(
                            child: FusionAppText(
                              text: "REDUCTION",
                              style: context.textTheme.labelMedium?.copyWith(
                                color: context.colorScheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SimpleVerticalMeter(
                              value:
                                  context
                                      .watch<AgcController>()
                                      .currentReduction,
                              min: -60,
                              max: 12,
                            ),
                          ),
                        ),
                        Container(
                          width: 120,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.colorScheme.elevation2,
                            border: Border(
                              top: BorderSide(
                                color: context.colorScheme.strokeLight,
                              ),
                            ),
                          ),
                          child: NeumorphicGainTextField(
                            controllerValue: 10,
                            maxGain: 12,
                            minGain: -60,
                            showDbSuffix: false,
                            onSubmitted:
                                context.read<AgcController>().updateReduction,
                          ),
                        ),
                        FusionAppText(
                          text: "dBFS",
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.colorScheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(
                  color: context.colorScheme.elevation1,
                  width: 0,
                  thickness: 2,
                ),
                PBSection(
                  type: PBSectionType.right,
                  child: SizedBox(
                    width: _sectionWidth,
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.colorScheme.elevation2,
                            border: Border(
                              bottom: BorderSide(
                                color: context.colorScheme.strokeLight,
                              ),
                            ),
                          ),
                          child: Center(
                            child: FusionAppText(
                              text: "OUTPUT",
                              style: context.textTheme.labelMedium?.copyWith(
                                color: context.colorScheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const Flexible(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: VerticalMeter(
                              min: -60,
                              max: 0,
                              value: -10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // children: <Widget>[
            //   ...getBlockHeader(
            //     context,
            //     pb,
            //     actions: <Widget>[
            //       const FusionAppText(text: "BYPASS"),
            //       const SizedBox(width: 10),
            //       FusionSwitch(
            //         inactiveTrackColor: context.colorScheme.elevation1,
            //         value: context.watch<AgcController>().isGloballyBypassed,
            //         onChanged: (bool value) {
            //           context.read<AgcController>().bypassGlobally(value);
            //         },
            //         height: 30,
            //         width: 50,
            //       ),
            //       const SizedBox(width: 20),
            //     ],
            //   ),

            //   Padding(
            //     padding: const EdgeInsetsGeometry.only(top: 50),
            //     child: DisabledWidgetWrapper(
            //       isDisabled: context.watch<AgcController>().isGloballyBypassed,
            //       child: ClipRRect(
            //         borderRadius: BorderRadius.circular(FusionSizes.borderRadius16),
            //         child: Container(
            //           color: context.colorScheme.elevation2,
            //           child:
            //         ),
            //       ),
            //     ),
            //   ),
            // ],
          );
        },
      ),
    );
  }
}
