import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/processing_blocks/widgets/block_header.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/widgets.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../add_source_popup/view_model/add_source_viewmodel.dart';
import '../../../viewmodel/algorithm_data_viewmodel.dart';
import '../../widgets/pb_meter.dart';
import '../widgets/disabled_widget_wrapper.dart';

part '_graphiceq_controller.dart';

const double _sectionWidth = 48.0;

class GraphicEqBlock extends StatelessWidget {
  const GraphicEqBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final AlgorithmDataViewmodel watch = context.watch<AlgorithmDataViewmodel>();

    return ProxyProvider<AlgorithmDataViewmodel, GraphicEqController>(
      key: ValueKey<String>(watch.processingBlock.id),
      create: (BuildContext context) => GraphicEqController(watch),
      update: (BuildContext context, AlgorithmDataViewmodel valueHandler, GraphicEqController? previous) => GraphicEqController(valueHandler),
      child: Builder(
        builder: (BuildContext context) {
          final ProcessingBlockModel pb = context.watch<AlgorithmDataViewmodel>().processingBlock;

          return Stack(
            children: <Widget>[
              ...getBlockHeader(
                context,
                pb,
                actions: <Widget>[
                  const FusionAppText(text: "BYPASS"),
                  const SizedBox(width: 10),
                  FusionSwitch(
                    inactiveTrackColor: context.colorScheme.elevation1,
                    value: context.watch<GraphicEqController>().isGloballyBypassed,
                    onChanged: (bool value) {
                      context.read<GraphicEqController>().bypassGlobally(value);
                    },
                    height: 30,
                    width: 50,
                  ),
                  const SizedBox(width: 20),
                ],
              ),

              Padding(
                padding: const EdgeInsetsGeometry.only(top: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    FusionNeumorphicButton(
                      text: "Flatten all",
                      width: 100,
                      height: 34,
                      onTap: () => context.read<GraphicEqController>().flattenAll(),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: DisabledWidgetWrapper(
                        isDisabled: context.watch<GraphicEqController>().isGloballyBypassed,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: LayoutBuilder(
                                builder: (BuildContext context, BoxConstraints constraints) {
                                  final int totalBands = GraphicEqController.totalGraphicEqBands;
                                  final double bandWidth = constraints.maxWidth / totalBands;

                                  return Row(
                                    children: List<Widget>.generate(totalBands, (int index) {
                                      final double value = context.watch<GraphicEqController>().getBandValue(index);

                                      return SizedBox(
                                        width: bandWidth,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: <Widget>[
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 90),
                                              decoration: BoxDecoration(
                                                color: index.isOdd ? context.colorScheme.elevation2 : null,
                                                borderRadius: BorderRadius.circular(
                                                  FusionSizes.borderRadius2,
                                                ),
                                              ),
                                              child: Column(
                                                children: <Widget>[
                                                  Expanded(
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                      child: VerticalSlider(
                                                        showIntervals: false,
                                                        value: value,
                                                        max: 15,
                                                        min: -15,
                                                        onChanged: (num v) => context.read<GraphicEqController>().updateBandValue(index, v),
                                                      ),
                                                    ),
                                                  ),
                                                  FusionAppText(
                                                    text: formatFrequency(
                                                      GraphicEqController.graphicEqFrequencies[index],
                                                    ),
                                                    style: context.textTheme.labelSmall?.copyWith(fontSize: 11),
                                                  ),
                                                  const SizedBox(height: 8),
                                                ],
                                              ),
                                            ),

                                            // Number Field
                                            Positioned(
                                              bottom: index.isEven ? 0 : 45,
                                              left: -bandWidth * 0.3,
                                              child: SizedBox(
                                                width: bandWidth * 1.5,
                                                child: PBNumberTextField(
                                                  min: -15,
                                                  max: 15,
                                                  value: value,
                                                  onChanged: (num v) => context.read<GraphicEqController>().updateBandValue(index, v),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(width: 10),

                            // dB + Hz scale
                            const Column(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      FusionAppText(text: "+15"),
                                      FusionAppText(text: "0"),
                                      FusionAppText(text: "-15"),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                                FusionAppText(text: "Hz"),
                                SizedBox(height: 55),
                                FusionAppText(text: "dB"),
                                SizedBox(height: 30),
                              ],
                            ),

                            const SizedBox(width: 20),

                            // Output Meter
                            Container(
                              decoration: BoxDecoration(
                                color: context.colorScheme.elevation2,
                                borderRadius: BorderRadius.circular(FusionSizes.borderRadius16),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: context.colorScheme.strokeLight),
                                      ),
                                    ),
                                    child: FusionAppText(
                                      text: "OUTPUT",
                                      style: context.textTheme.labelMedium?.copyWith(
                                        color: context.colorScheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const Flexible(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

final NumberFormat _kFormatter = NumberFormat("0.##");
final NumberFormat _hzFormatter = NumberFormat("0.##");

String formatFrequency(num freq) {
  if (freq >= 1000) {
    final double k = freq / 1000;
    return "${_kFormatter.format(k)}K";
  }

  return _hzFormatter.format(freq);
}
