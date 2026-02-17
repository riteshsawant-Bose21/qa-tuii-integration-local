import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/add_source_popup/view_model/add_source_viewmodel.dart';
import 'package:fusion_launcher/features/processing_block/view/processing_blocks/widgets/out_meter.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import '../../../viewmodel/algorithm_data_viewmodel.dart';
import '../widgets/block_header.dart';
import '../widgets/disabled_widget_wrapper.dart';
import '_tone_control_widget.dart';
part '_tone_control_controller.dart';

class ToneControlBlock extends StatelessWidget {
  const ToneControlBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final AlgorithmDataViewmodel watch = context.watch<AlgorithmDataViewmodel>();
    return ProxyProvider<AlgorithmDataViewmodel, ToneController>(
      key: ValueKey<String>(watch.processingBlock.id),
      create: (BuildContext context) {
        return ToneController(watch);
      },
      update: (BuildContext context, AlgorithmDataViewmodel valueHandler, ToneController? previous) => ToneController(valueHandler),
      child: Builder(
        builder: (BuildContext context) {
          return Stack(
            children: <Widget>[
              ...getBlockHeader(
                context,
                context.watch<AlgorithmDataViewmodel>().processingBlock,
                actions: <Widget>[
                  const FusionAppText(text: "BYPASS"),
                  const SizedBox(width: 10),
                  FusionSwitch(
                    inactiveTrackColor: context.colorScheme.elevation1,
                    value: context.watch<ToneController>().isGloballyBypassed,
                    onChanged: (bool value) {
                      context.read<ToneController>().bypassGlobally(value);
                    },
                    height: 30,
                    width: 50,
                  ),
                ],
              ),

              /// Main content area
              Padding(
                padding: const EdgeInsetsGeometry.only(top: 50),
                child: DisabledWidgetWrapper(
                  isDisabled: context.watch<ToneController>().isGloballyBypassed,
                  child: Row(
                    spacing: 3,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      ToneControlWidget(
                        title: "LOW",
                        isDisabled: context.watch<ToneController>().isLowBypassed,
                        value: context.watch<ToneController>().currentLowGain ?? 0,
                        onChanged: (num value) {
                          context.read<ToneController>().updateLowGain(value);
                        },
                        isBypassed: context.watch<ToneController>().isLowBypassed,
                        onBypassChanged: (bool value) {
                          context.read<ToneController>().updateLowBypass(value);
                        },
                      ),
                      ToneControlWidget(
                        title: "MID",
                        isDisabled: context.watch<ToneController>().isMidBypassed,

                        value: context.watch<ToneController>().currentMidGain ?? 0,
                        onChanged: (num value) {
                          context.read<ToneController>().updateMidGain(value);
                        },
                        isBypassed: context.watch<ToneController>().isMidBypassed,
                        onBypassChanged: (bool value) {
                          context.read<ToneController>().updateMidBypass(value);
                        },
                      ),
                      ToneControlWidget(
                        title: "HIGH",
                        isDisabled: context.watch<ToneController>().isHighBypassed,

                        value: context.watch<ToneController>().currentHighGain ?? 0,
                        onChanged: (num value) {
                          context.read<ToneController>().updateHighGain(value);
                        },
                        isBypassed: context.watch<ToneController>().isHighBypassed,
                        onBypassChanged: (bool value) {
                          context.read<ToneController>().updateHighBypass(value);
                        },
                      ),
                      const OutMeter(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
