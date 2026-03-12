import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/add_source_popup/view_model/add_source_viewmodel.dart';
import 'package:fusion_launcher/features/processing_block/view/processing_blocks/widgets/pb_section.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/widgets.dart';
import 'package:fusion_launcher/features/processing_block/viewmodel/algorithm_data_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import '../../widgets/pb_out_meter.dart';
import '../widgets/pb_block_layout.dart';
import '../widgets/pb_content_section.dart';

part '_gate_controller.dart';
part '_gate_graph.dart';

class GateBlock extends StatelessWidget {
  const GateBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final AlgorithmDataViewmodel watch = context.watch<AlgorithmDataViewmodel>();
    final String targetBlockId = watch.processingBlock.id;
    return ProxyProvider<AlgorithmDataViewmodel, GateController>(
      key: ValueKey<String>(watch.processingBlock.id),
      create: (BuildContext context) {
        return GateController(watch);
      },
      update: (BuildContext context, AlgorithmDataViewmodel valueHandler, GateController? previous) => GateController(valueHandler),
      child: Builder(
        builder: (BuildContext context) {
          final GateController controller = context.watch<GateController>();
          return PBBlockLayout(
            pb: context.watch<AlgorithmDataViewmodel>().processingBlock,
            onBypassChanged: context.read<GateController>().bypassGlobally,
            bypassed: controller.isGloballyBypassed,
            body: Row(
              spacing: 3,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                PBSection(
                  type: PBSectionType.left,
                  child: SizedBox(
                    width: 120,
                    child: PbContentSection(
                      title: "THRESHOLD",
                      footer: SizedBox(
                        width: 100,
                        child: Column(
                          spacing: 10,
                          children: <Widget>[
                            PBNumberTextField(
                              value: controller.threshold ?? 0,
                              max: 0,
                              min: -60,
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
                        value: controller.threshold ?? 0,
                        max: 0,
                        min: -60,
                        onChanged: (num value) {
                          controller.updateThreshold(value);
                        },
                      ),
                    ),
                  ),
                ),
                PBSection(
                  type: PBSectionType.middle,
                  child: SizedBox(
                    width: 120,

                    child: PbContentSection(
                      title: "RANGE",
                      footer: SizedBox(
                        width: 100,
                        child: Column(
                          spacing: 10,
                          children: <Widget>[
                            PBNumberTextField(
                              value: controller.range ?? 0,
                              max: 0.0,
                              min: -70,
                              onChanged: (num value) {
                                controller.updateRange(value);
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
                        value: controller.range ?? 0,
                        max: 0.0,
                        min: -70,
                        onChanged: (num value) {
                          controller.updateRange(value);
                        },
                      ),
                    ),
                  ),
                ),
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
                            title: "HOLD",
                            value: controller.hold ?? 0.1,
                            min: 0.1,
                            max: 1000.0,
                            onChanged: (num value) {
                              controller.updateHold(value);
                            },
                          ),
                          Divider(
                            color: context.colorScheme.strokeLight,
                            height: 30,
                          ),
                          _GateTextField(
                            title: "DECAY",
                            value: controller.decay ?? 5.0,
                            min: 5.0,
                            max: 50000.0,
                            onChanged: (num value) {
                              controller.updateDecay(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: PBSection(
                    type: PBSectionType.middle,
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 50,
                        ),
                        Expanded(child: _GateGraph()),
                      ],
                    ),
                  ),
                ),
                 PBSection(
                  type: PBSectionType.right,
                  child: SizedBox(
                    width: 100,
                    child: PbContentSection(
                      title: "OUTPUT",
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: PbOutMeter(
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
  });
  final num value;
  final num? min;
  final num? max;
  final ValueChanged<num> onChanged;
  final String title;
  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
