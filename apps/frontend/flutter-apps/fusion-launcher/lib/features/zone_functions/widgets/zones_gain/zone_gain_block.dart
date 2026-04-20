import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_vertical_slider.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/processing_block_model.dart';

import '../../../../core/models/algorithm/algorithm_metadata.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../processing_block/view/processing_blocks/gain/gain_block.dart';
import '../../../processing_block/view/widgets/pb_out_meter.dart';
import '../../../processing_block/view/widgets/pb_textfield.dart';
import '../../../processing_block/viewmodel/algorithm_data_viewmodel.dart';
import '../../source_mix.dart';
import '../neumorphic_audio_toggle_button.dart';
import 'package:provider/provider.dart';

class ZonesGainBlockWidget extends StatelessWidget {
  const ZonesGainBlockWidget({
    super.key,
    required this.isSubZonesAvailable,
    required this.title,
    required this.projectViewModel,
    required this.zoneOrSubzoneID,
    required this.widget,
    required this.processingBlock,
    required this.index,
  });

  final bool isSubZonesAvailable;
  final String? title;
  final ProjectViewModel projectViewModel;
  final String zoneOrSubzoneID;
  final ZoneControlSliderBuilder widget;
  final ProcessingBlockModel processingBlock;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AlgorithmDataViewmodel>(
      key: ValueKey<String>(processingBlock.id),
      create: (BuildContext context) => AlgorithmDataViewmodel(processingBlock: processingBlock, config: serviceLocator.get<FusionAlgorithmsConfig>()),

      child: Consumer<AlgorithmDataViewmodel>(
        builder: (BuildContext context, AlgorithmDataViewmodel viewModel, Widget? child) {
          final AlgorithmDataViewmodel watch = context.watch<AlgorithmDataViewmodel>();
          return Container(
            width: 150,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: context.colorScheme.strokeLight,
                ),
                top:
                    isSubZonesAvailable
                        ? BorderSide(
                          color: context.colorScheme.strokeLight,
                        )
                        : BorderSide.none,
              ),
            ),
            child: SemanticHelper.container(
              testId: SemanticHelper.createTestId(SemanticTypes.container, 'zone_subzone_control_item_$index'),
              child: ProxyProvider<AlgorithmDataViewmodel, GainController>(
                key: ValueKey<String>(processingBlock.id),
                create: (BuildContext context) {
                  return GainController(watch);
                },
                update: (BuildContext context, AlgorithmDataViewmodel valueHandler, GainController? previous) => GainController(valueHandler),
                child: Builder(
                  builder: (BuildContext context) {
                    return Column(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          alignment: Alignment.center,
                          child: FusionAppText(
                            text: title ?? "",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Divider(
                          color: context.colorScheme.strokeLight,
                          height: 0,
                        ),
                        const SizedBox(height: 10),
                        SemanticHelper.formControl(
                          testId: SemanticHelper.createTestId(
                            SemanticTypes.formControl,
                            "source_mix_zone_gain_text_field",
                          ),
                          child: PBNumberTextField(
                            semanticId: 'source_mix_zone_gain_text_field',
                            value: (context.watch<GainController>().currentGainValue ?? 0).toDouble(),
                            onChanged: (num value) {
                              context.read<GainController>().updateGainValue(value);
                            },
                            min: -60,
                            max: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      VerticalSlider(
                                        semanticId: 'slider_and_meter_widget',
                                        value: context.watch<GainController>().currentGainSliderValue ?? 0,
                                        min: -60.0,
                                        max: 12.0,
                                        showIntervals: true,
                                        activeColor: context.colorScheme.primary,
                                        onChanged: (num value) {
                                          context.read<GainController>().updateGainSliderValue(value);
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: PbOutMeter(
                                          semanticId: '_output',
                                          blockId: processingBlock.id,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SemanticHelper.button(
                                testId: SemanticHelper.createTestId(
                                  SemanticTypes.button,
                                  "source_mix_mute_button",
                                ),
                                child: NeumorphicAudioToggleButton(
                                  isActive: context.watch<GainController>().isGainMuted,
                                  backgroundColor: context.colorScheme.elevation2,
                                  width: 100,
                                  onTap: () {
                                    final bool isCurrentlyMuted = context.read<GainController>().isGainMuted;
                                    context.read<GainController>().toggleGainMute(!isCurrentlyMuted);
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
