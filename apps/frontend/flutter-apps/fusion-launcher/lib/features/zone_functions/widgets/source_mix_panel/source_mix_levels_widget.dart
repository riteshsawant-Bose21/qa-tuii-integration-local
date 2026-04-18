import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../projects/models/meter_data.dart';
import '../../../projects/view_model/meter_data/meter_data_view_model.dart';
import '../../view_model/source_mix/source_mix_view_model.dart';
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
  late final SourceMixViewModel _sourceMixViewModel;
  late final MeterDataViewModel _meterDataViewModel;

  late List<Source> sources;

  @override
  void initState() {
    super.initState();
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(
      zoneId: widget.zoneID,
    );

    _sourceMixViewModel = SourceMixViewModel();
    _meterDataViewModel = serviceLocator<MeterDataViewModel>();

    // Register as meter observer so telemetry stays alive while this widget is mounted.
    _meterDataViewModel.registerObserver();

    // Fetch the latest server values on load.
    _sourceMixViewModel.updateParamsAsPerServer(function: widget.zoneFunctions);

    // Subscribe to live WebSocket block-data updates for cross-device sync.
    _sourceMixViewModel.subscribeToBlockData(functionId: widget.zoneFunctions.id);
  }

  @override
  void dispose() {
    _sourceMixViewModel.unsubscribeFromBlockData();
    _sourceMixViewModel.close();
    _meterDataViewModel.unregisterObserver();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch ProjectViewModel to rebuild when mix settings change.
    context.watch<ProjectViewModel>();

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

                    final int sourceChannelIndex =
                        widget.zoneFunctions.sourceIndex != null && widget.zoneFunctions.sourceIndex!.containsKey(source.id)
                            ? widget.zoneFunctions.sourceIndex![source.id]!
                            : 0;
                    final int sourceIndexForControl = sourceChannelIndex;
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
                                    // Input presence indicator — driven by meter data.
                                    _InputPresenceIndicator(
                                      blockId: widget.zoneFunctions.id,
                                      dimension: sourceIndexForControl,
                                      meterDataViewModel: _meterDataViewModel,
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
                                maxGain: 0,
                                onSubmitted: (double value) {
                                  _sourceMixViewModel.updateGain(
                                    function: widget.zoneFunctions,
                                    sourceId: source.id,
                                    mixSetting: mixSetting,
                                    gain: value,
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
                                          _sourceMixViewModel.updateGain(
                                            function: widget.zoneFunctions,
                                            sourceId: source.id,
                                            mixSetting: mixSetting,
                                            gain: value.toDouble(),
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
                                        _sourceMixViewModel.updateMuted(
                                          function: widget.zoneFunctions,
                                          sourceId: source.id,
                                          mixSetting: mixSetting,
                                          isMuted: !mixSetting.muted,
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

// ─────────────────────────────────────────────────────────────────────────────
// _InputPresenceIndicator
//
// A small coloured square that turns green when the meter data reports
// input_presence ≥ 1.0 for the given [blockId] + [dimension].
// Uses BlocSelector to rebuild only when the relevant value changes.
// ─────────────────────────────────────────────────────────────────────────────

class _InputPresenceIndicator extends StatelessWidget {
  final String blockId;
  final int dimension;
  final MeterDataViewModel meterDataViewModel;

  const _InputPresenceIndicator({
    required this.blockId,
    required this.dimension,
    required this.meterDataViewModel,
  });

  /// Searches all packets for a [MeterBlock] whose `blockName` matches
  /// [blockId] and whose `meterName` is `input_presence`.
  static MeterBlock? _findInputPresenceBlock(
    MeterDataState state,
    String blockId,
  ) {
    for (final MeterPacket packet in state.packets.values) {
      for (final MeterBlock block in packet.blocks) {
        if (block.blockName == blockId && block.meterName == 'input_presence') {
          return block;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MeterDataViewModel, MeterDataState, bool>(
      bloc: meterDataViewModel,
      selector: (MeterDataState state) {
        final MeterBlock? meter = _findInputPresenceBlock(state, blockId);
        print("Debug: Checking input presence for blockId=$blockId, dimension=$dimension. Meter found: ${meter != null}. Meter value: ${meter?.value}");
        if (meter == null || dimension < 0 || dimension >= meter.value.length) return false;
        return meter.value[dimension] >= 1.0;
      },
      builder: (BuildContext context, bool isPresent) {
        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(
            SemanticTypes.container,
            'input_presence_${blockId}_$dimension',
          ),
          child: Container(
            height: 16,
            width: 16,
            decoration: BoxDecoration(
              color:
                  isPresent
                      ? const Color(0xFF48BB78) // green — signal present
                      : context.colorScheme.iconDisabled, // grey — no signal
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}
