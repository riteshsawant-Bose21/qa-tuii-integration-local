import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../horizontal_scroll_effect_wrapper.dart';
import '../neumorphic_audio_toggle_button.dart';
import '../neumorphic_gain_text_field.dart';

class SourceMixLeftWidget extends StatefulWidget {
  final String zoneID;
  final ZoneFunctions zoneFunctions;

  const SourceMixLeftWidget({
    super.key,
    required this.zoneID,
    required this.zoneFunctions,
  });

  @override
  State<SourceMixLeftWidget> createState() => _SourceMixLeftWidgetState();
}

class _SourceMixLeftWidgetState extends State<SourceMixLeftWidget> {
  late final ScrollController _scrollController = ScrollController();

  late List<Source> sources;

  @override
  void initState() {
    super.initState();
    late final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(
      zoneId: widget.zoneID,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FusionAppText(
            text: "SOURCES",
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: Builder(
            builder: (BuildContext context) {
              if (sources.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: context.colorScheme.strokeLight,
                      ),
                    ),
                  ),
                  child: Center(
                    child: FusionAppText(
                      text: "No sources selected for this function",
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.colorScheme.textPlaceholder,
                      ),
                    ),
                  ),
                );
              }

              return HorizontalScrollWithShadows(
                controller: _scrollController,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List<Widget>.generate(sources.length, (int index) {
                    final Source source = sources[index];

                    final MixSettings mixSetting = widget.zoneFunctions.mixSettings!.singleWhere(
                      (MixSettings setting) => setting.sourceId == source.id,
                      orElse:
                          () => MixSettings(
                            sourceId: source.id,
                            gain: 0,
                            muted: true,
                          ),
                    );

                    return Container(
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: context.colorScheme.strokeLight,
                          ),
                          right: BorderSide(
                            color: context.colorScheme.strokeLight,
                          ),
                        ),
                      ),
                      child: SemanticHelper.container(
                        testId: SemanticHelper.createTestId(SemanticTypes.container, 'sourcemix_source_$index'),
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsetsGeometry.all(16),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      height: 16,
                                      width: 16,
                                      decoration: BoxDecoration(
                                        color: context.colorScheme.iconDisabled,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FusionAppText(
                                      text: source.name,
                                      textAlign: TextAlign.center,
                                      maxLine: 1,
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              color: context.colorScheme.strokeLight,
                              height: 0,
                            ),
                            const SizedBox(height: 10),
                            SemanticHelper.formControl(
                              testId: SemanticHelper.createTestId(
                                SemanticTypes.textInput,
                                "source_mix_gain_text_field",
                              ),
                              child: NeumorphicGainTextField(
                                semanticId: 'source_mix_gain_text_field',
                                controllerValue: mixSetting.gain,
                                minGain: -60,
                                maxGain: 12,
                                onSubmitted: (double value) {
                                  projectViewModel.updateMixSettings(
                                    mixSettings: mixSetting.copyWith(
                                      gain: value,
                                    ),
                                    functionId: widget.zoneFunctions.id,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Column(
                                children: <Widget>[
                                  Expanded(
                                    child: SemanticHelper.button(
                                      testId: SemanticHelper.createTestId(
                                        SemanticTypes.button,
                                        "source_mix_gain_slider",
                                      ),
                                      child: VerticalSlider(
                                        semanticId: 'slider_and_meter_widget',
                                        onChanged: (num value) {
                                          projectViewModel.updateMixSettings(
                                            mixSettings: mixSetting.copyWith(
                                              gain: value.toDouble(),
                                            ),
                                            functionId: widget.zoneFunctions.id,
                                          );
                                        },
                                        value: mixSetting.gain,
                                        min: -60,
                                        max: 0.0,
                                        intervalGap: 6,
                                      ),
                                    ),
                                  ),
                                  SemanticHelper.button(
                                    testId: SemanticHelper.createTestId(
                                      SemanticTypes.button,
                                      "source_mix_mute_button",
                                    ),
                                    child: NeumorphicAudioToggleButton(
                                      isActive: mixSetting.muted,
                                      backgroundColor: context.colorScheme.elevation2,
                                      width: 100,
                                      onTap: () {
                                        projectViewModel.updateMixSettings(
                                          mixSettings: mixSetting.copyWith(
                                            muted: !mixSetting.muted,
                                          ),
                                          functionId: widget.zoneFunctions.id,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
