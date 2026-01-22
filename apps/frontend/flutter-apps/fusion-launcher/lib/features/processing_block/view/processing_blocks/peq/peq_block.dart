import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/add_source_popup/view_model/add_source_viewmodel.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_meter.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../viewmodel/algorithm_data_viewmodel.dart';
import '../../widgets/pb_dropdown.dart';
import '../../widgets/pb_textfield.dart';
import '../widgets/block_header.dart';
import '../widgets/disabled_widget_wrapper.dart';

part '_peq_band_section.dart';
part '_peq_controller.dart';
part '_peq_graph.dart';
part '_peq_out_meter.dart';

class PeqBlock extends StatelessWidget {
  const PeqBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final AlgorithmDataViewmodel watch = context.watch<AlgorithmDataViewmodel>();
    return ProxyProvider<AlgorithmDataViewmodel, PEQController>(
      key: ValueKey<String>(watch.processingBlock.id),
      create: (BuildContext context) {
        return PEQController(watch);
      },
      update: (BuildContext context, AlgorithmDataViewmodel valueHandler, PEQController? previous) => PEQController(valueHandler),
      child: Builder(
        builder: (BuildContext context) {
          return Column(
            spacing: 10,
            children: <Widget>[
              BlockHeader(
                pb: context.watch<AlgorithmDataViewmodel>().processingBlock,
                actions: Row(
                  children: <Widget>[
                    FusionNeumorphicButton(
                      text: "SORT",
                      width: 100,
                      height: 40,
                      onTap: () {
                        context.read<PEQController>().sortBandsByFrequency();
                      },
                    ),
                    const SizedBox(width: 10),
                    FusionContainer(
                      raised: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20),
                        child: Row(
                          spacing: 10,
                          children: <Widget>[
                            const FusionAppText(text: "Q"),
                            FusionSwitch(
                              inactiveTrackColor: context.colorScheme.elevation1,
                              value: context.watch<PEQController>().isInBW,
                              onChanged: (bool value) {
                                context.read<PEQController>().toggleQAndBw(value);
                              },
                              height: 30,
                              width: 50,
                            ),
                            const FusionAppText(text: "BW"),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 70,
                    ),
                    const FusionAppText(text: "BYPASS"),
                    const SizedBox(width: 10),
                    FusionSwitch(
                      inactiveTrackColor: context.colorScheme.elevation1,
                      value: context.watch<PEQController>().isGloballyBypassed,
                      onChanged: (bool value) {
                        context.read<PEQController>().bypassGlobally(value);
                      },
                      height: 30,
                      width: 50,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: DisabledWidgetWrapper(
                  isDisabled: context.watch<PEQController>().isGloballyBypassed,
                  child: const Row(
                    spacing: 4,
                    children: <Widget>[
                      Expanded(child: _PeqGraphSection()),
                      SizedBox(width: 600, child: _PeqBandSection()),
                      _PeqOutMeter(),
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
