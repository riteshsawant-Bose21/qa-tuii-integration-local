import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/processing_blocks/widgets/block_header.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/widgets.dart';
import 'package:fusion_launcher/features/zone_functions/widgets/horizontal_scroll_effect_wrapper.dart';
import 'package:fusion_launcher/features/zone_functions/widgets/neumorphic_gain_text_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../add_source_popup/view_model/add_source_viewmodel.dart';
import '../../../viewmodel/algorithm_data_viewmodel.dart';
import '../widgets/disabled_widget_wrapper.dart';

part '_graphiceq_controller.dart';

const double _sectionWidth = 48.0;

class GraphicEqBlock extends StatefulWidget {
  const GraphicEqBlock({super.key});

  @override
  State<GraphicEqBlock> createState() => _GraphicEqBlockState();
}

class _GraphicEqBlockState extends State<GraphicEqBlock> {
  late final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

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
                              child: HorizontalScrollWithShadows(
                                controller: scrollController,
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      ...List<Widget>.generate(GraphicEqController.totalGraphicEqBands, (int index) {
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 90),
                                              child: Container(
                                                width: _sectionWidth,
                                                decoration: BoxDecoration(
                                                  color: index.isOdd ? context.colorScheme.elevation2 : null,
                                                  borderRadius: BorderRadius.circular(FusionSizes.borderRadius2),
                                                ),
                                                child: Column(
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                        child: VerticalSlider(
                                                          showIntervals: false,
                                                          value: context.watch<GraphicEqController>().getBandValue(index),
                                                          max: 15,
                                                          min: -15,
                                                          onChanged: (num value) => context.read<GraphicEqController>().updateBandValue(index, value),
                                                        ),
                                                      ),
                                                    ),
                                                    FusionAppText(
                                                      text: formatFrequency(GraphicEqController.graphicEqFrequencies[index]),
                                                      style: context.textTheme.labelSmall?.copyWith(fontSize: 12),
                                                    ),
                                                    const SizedBox(height: 10),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            if (index.isEven) ...<Widget>[
                                              Positioned(
                                                bottom: 0,
                                                right: -10,
                                                child: NeumorphicGainTextField(
                                                  controllerValue: context.watch<GraphicEqController>().getBandValue(index),
                                                  maxGain: 15,
                                                  minGain: -15,
                                                  width: _sectionWidth + 15,
                                                  showDbSuffix: false,
                                                  backgroundColor: context.colorScheme.elevation1,
                                                  onSubmitted: (double value) => context.read<GraphicEqController>().updateBandValue(index, value),
                                                ),
                                              ),
                                            ],

                                            if (!index.isEven) ...<Widget>[
                                              Positioned(
                                                bottom: 45,
                                                right: -10,
                                                child: NeumorphicGainTextField(
                                                  controllerValue: context.watch<GraphicEqController>().getBandValue(index),
                                                  onSubmitted: (double value) => context.read<GraphicEqController>().updateBandValue(index, value),
                                                  maxGain: 15,
                                                  minGain: -15,
                                                  width: _sectionWidth + 15,
                                                  showDbSuffix: false,
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      FusionAppText(text: "+15", style: context.textTheme.labelSmall),
                                      FusionAppText(text: "+15", style: context.textTheme.labelSmall),
                                      FusionAppText(text: "+15", style: context.textTheme.labelSmall),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FusionAppText(
                                  text: "Hz",
                                  style: context.textTheme.labelSmall,
                                ),
                                const SizedBox(height: 55),
                                FusionAppText(
                                  text: "dB",
                                  capitalize: false,
                                  style: context.textTheme.labelSmall,
                                ),
                                const SizedBox(height: 30),
                              ],
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
