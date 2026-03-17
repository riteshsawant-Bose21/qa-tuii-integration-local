import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/processing_blocks/widgets/pb_section.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_out_meter.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/widgets.dart';
import 'package:fusion_launcher/features/processing_block/viewmodel/algorithm_data_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import '../widgets/pb_block_layout.dart';
import '../widgets/pb_content_section.dart';

part '_compressor_controller.dart';

part '_compressor_graph.dart';

class CompressorBlock extends StatelessWidget {
  const CompressorBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final AlgorithmDataViewmodel watch = context.watch<AlgorithmDataViewmodel>();
    final String targetBlockId = watch.processingBlock.id;
    return ProxyProvider<AlgorithmDataViewmodel, CompressorController>(
      key: ValueKey<String>(watch.processingBlock.id),
      create: (BuildContext context) {
        return CompressorController(watch);
      },
      update: (BuildContext context, AlgorithmDataViewmodel valueHandler, CompressorController? previous) => CompressorController(valueHandler),
      child: Builder(
        builder: (BuildContext context) {
          final CompressorController controller = context.watch<CompressorController>();
          return PBBlockLayout(
            pb: context.watch<AlgorithmDataViewmodel>().processingBlock,
            onBypassChanged: context.read<CompressorController>().bypassGlobally,
            bypassed: controller.isGloballyBypassed,
            body: Row(
              spacing: 3,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                /// Threshold Section
                PBSection(
                  semanticId: 'compressor_threshold',
                  type: PBSectionType.left,
                  child: SizedBox(
                    width: 120,
                    child: PbContentSection(
                      semanticId: 'compressor_threshold',
                      title: "THRESHOLD",
                      footer: SizedBox(
                        width: 100,
                        child: Column(
                          spacing: 10,
                          children: <Widget>[
                            PBNumberTextField(
                              value: controller.threshold ?? 0,
                              max: 0.0,
                              min: -40,
                              onChanged: (num value) {
                                controller.updateThreshold(value);
                              },
                            ),
                            FusionAppText(
                              text: "dBFS",
                              capitalize: false,
                              style: context.textTheme.labelMedium?.copyWith(
                                color: context.colorScheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: VerticalSlider(
                        semanticId: 'compressor_threshold',
                        value: controller.threshold ?? 0,
                        max: 0.0,
                        min: -40,
                        intervalGap: 12,
                        onChanged: (num value) {
                          controller.updateThreshold(value);
                        },
                      ),
                    ),
                  ),
                ),

                /// Ratio Section
                PBSection(
                  type: PBSectionType.middle,
                  child: SizedBox(
                    width: 120,

                    child: PbContentSection(
                      semanticId: 'compressor_ratio',
                      title: "RATIO",
                      footer: SizedBox(
                        width: 100,
                        child: Column(
                          spacing: 10,
                          children: <Widget>[
                            PBNumberTextField(
                              value: controller.ratio ?? 0,
                              max: 1.0,
                              min: 20,
                              onChanged: (num value) {
                                controller.updateRatio(value);
                              },
                            ),
                            FusionAppText(
                              capitalize: false,
                              text: "dB",
                              style: context.textTheme.labelMedium?.copyWith(
                                color: context.colorScheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: VerticalSlider(
                        semanticId: 'Ration_dB',
                        value: controller.ratio ?? 0,
                        max: 20.0,
                        min: 1,
                        // intervalGap: 1,
                        onChanged: (num value) {
                          controller.updateRatio(value);
                        },
                      ),
                    ),
                  ),
                ),

                /// Time Settings Section
                PBSection(
                  type: PBSectionType.middle,
                  child: SizedBox(
                    width: 200,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: <Widget>[
                          /// Top header Space
                          const SizedBox(
                            height: 50,
                          ),
                          _GateTextField(
                            semanticId: 'compressor_attack',
                            title: "ATTACK",
                            value: controller.attack ?? 0.5,
                            min: 0.5,
                            max: 100.0,
                            onChanged: (num value) {
                              controller.updateAttack(value);
                            },
                          ),
                          Divider(
                            color: context.colorScheme.strokeLight,
                            height: 30,
                          ),
                          _GateTextField(
                            semanticId: 'compressor_release',
                            title: "RELEASE",
                            value: controller.release ?? 5.0,
                            min: 5.0,
                            max: 50000.0,
                            onChanged: (num value) {
                              controller.updateRelease(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                /// Graph Section
                const Expanded(
                  child: PBSection(
                    semanticId: 'compressor_graph',
                    type: PBSectionType.middle,
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 50,
                        ),
                        Expanded(child: _CompressorGraph()),
                      ],
                    ),
                  ),
                ),

                /// Releaser Section
                PBSection(
                  type: PBSectionType.middle,
                  child: SizedBox(
                    width: 120,

                    child: PbContentSection(
                      title: "Reduction",
                      semanticId: 'compressor_reduction',
                      footer: SizedBox(
                        width: 100,
                        child: Column(
                          spacing: 10,
                          children: <Widget>[
                            PBNumberTextField(
                              semanticId: 'compressor_reduction',
                              value: controller.reduction ?? 0,
                              max: 0.0,
                              min: -42,
                              onChanged: (num value) {
                                controller.updateReduction(value);
                              },
                            ),
                            FusionAppText(
                              capitalize: false,
                              text: "dB",
                              style: context.textTheme.labelMedium?.copyWith(
                                color: context.colorScheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: VerticalSlider(
                        semanticId: 'Reduction_dB',
                        value: controller.reduction ?? 0,
                        max: 0.0,
                        min: -42,
                        intervalGap: 6,
                        onChanged: (num value) {
                          controller.updateReduction(value);
                        },
                      ),
                    ),
                  ),
                ),

                /// Output Meter Section
                PBSection(
                  semanticId: 'compressor_output',
                  type: PBSectionType.right,
                  child: SizedBox(
                    width: 100,
                    child: PbContentSection(
                      semanticId: 'compressor_output',
                      title: "OUTPUT",
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: PbOutMeter(
                          semanticId: 'compressor_output',
                          blockId: targetBlockId,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GateTextField extends StatelessWidget {
  const _GateTextField({
    super.key,
    required this.value,
    this.min,
    this.max,
    required this.onChanged,
    required this.title,
    this.semanticId,
  });

  final String? semanticId;
  final num value;
  final num? min;
  final num? max;
  final ValueChanged<num> onChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.textInput,
        'compressor_gate_text_field${semanticId ?? ''}',
      ),
      label: value.toString(),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FusionAppText(
              text: title,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: PBNumberTextField(
              onChanged: onChanged,
              value: value,
              min: min,
              max: max,
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            "ms",
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
