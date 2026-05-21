import 'package:flutter/material.dart';
import 'package:flutter/src/services/text_formatter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/projects/view_model/spl_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../add_source_popup/view/widgets/common_widgets/add_sources_dropdown.dart';

class BuildingSplPanel extends StatelessWidget {
  const BuildingSplPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplViewModel, SplState>(
      builder: (BuildContext context, SplState state) {
        final SplPanelData panelData = state.panelData;
        final List<SplFrequency> frequencyOptions = _allowedFrequenciesFor(panelData.bandwidth);
        final bool needsFrequency = panelData.bandwidth == SplBandwidth.oneThirdOctave || panelData.bandwidth == SplBandwidth.oneOctave;
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                spacing: 12,
                children: <Widget>[
                  FusionOutlinedDropdown<SplBandwidth>(
                    label: "Bandwidth",
                    hint: "Select Bandwidth",
                    semanticId: "bandwidth",
                    items: SplBandwidth.values,
                    value: panelData.bandwidth,
                    itemLabelBuilder: (SplBandwidth bandwidth) => bandwidth.displayName,
                    onChanged: (SplBandwidth value) {
                      final List<SplFrequency> freqOptions = _allowedFrequenciesFor(value);
                      context.read<SplViewModel>().updatePanelData(panelData.copyWith(bandwidth: value, frequency: freqOptions.firstOrNull));
                    },
                  ),
                  if (needsFrequency)
                    FusionOutlinedDropdown<SplFrequency>(
                      label: "Frequency",
                      hint: "Select Frequency",
                      semanticId: "frequency",
                      items: frequencyOptions,
                      value: panelData.frequency,
                      itemLabelBuilder: (SplFrequency frequency) => frequency.displayName,
                      onChanged: (SplFrequency value) {
                        context.read<SplViewModel>().updatePanelData(panelData.copyWith(frequency: value));
                      },
                    ),
                  FusionOutlinedDropdown<SplWeighting>(
                    label: "Weighting",
                    hint: "Select Weighting",
                    semanticId: "weighting",
                    items: SplWeighting.values,
                    value: panelData.weighting,
                    itemLabelBuilder: (SplWeighting weighting) => weighting.displayName,
                    onChanged: (SplWeighting value) {
                      context.read<SplViewModel>().updatePanelData(panelData.copyWith(weighting: value));
                    },
                  ),
                ],
              ),
            ),

            // const Divider(),
          ],
        );
      },
    );
  }

  List<SplFrequency> _allowedFrequenciesFor(SplBandwidth bw) {
    if (bw == SplBandwidth.oneOctave) {
      // Octave centers within 31.5–16k
      return <SplFrequency>[
        SplFrequency.hz31_5,
        SplFrequency.hz63,
        SplFrequency.hz125,
        SplFrequency.hz250,
        SplFrequency.hz500,
        SplFrequency.hz1000,
        SplFrequency.hz2000,
        SplFrequency.hz4000,
        SplFrequency.hz8000,
        SplFrequency.hz16000,
      ];
    }
    if (bw == SplBandwidth.oneThirdOctave) {
      // Full 1/3-oct ISO list already declared in enum
      return <SplFrequency>[
        SplFrequency.hz31_5,
        SplFrequency.hz40,
        SplFrequency.hz50,
        SplFrequency.hz63,
        SplFrequency.hz80,
        SplFrequency.hz100,
        SplFrequency.hz125,
        SplFrequency.hz160,
        SplFrequency.hz200,
        SplFrequency.hz250,
        SplFrequency.hz315,
        SplFrequency.hz400,
        SplFrequency.hz500,
        SplFrequency.hz630,
        SplFrequency.hz800,
        SplFrequency.hz1000,
        SplFrequency.hz1250,
        SplFrequency.hz1600,
        SplFrequency.hz2000,
        SplFrequency.hz2500,
        SplFrequency.hz3150,
        SplFrequency.hz4000,
        SplFrequency.hz5000,
        SplFrequency.hz6300,
        SplFrequency.hz8000,
        SplFrequency.hz10000,
        SplFrequency.hz12500,
        SplFrequency.hz16000,
      ];
    }
    // Vocal/All Bands/Broadband don't use frequency
    return const <SplFrequency>[];
  }
}

class SplSettingPanel extends StatelessWidget {
  const SplSettingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplViewModel, SplState>(
      builder: (BuildContext context, SplState state) {
        final SplPanelData panelData = state.panelData;
        return Column(
          spacing: 12,
          children: <Widget>[
            FusionOutlinedDropdown<SplResolution>(
              label: "Resolution",
              hint: "Select Resolution",
              semanticId: "resolution",
              items: SplResolution.values,
              value: panelData.resolution,
              itemLabelBuilder: (SplResolution resolution) => resolution.displayName,
              onChanged: (SplResolution value) {
                context.read<SplViewModel>().updatePanelData(panelData.copyWith(resolution: value));
              },
            ),
            FusionOutlinedDropdown<SplMapping>(
              label: "Mapping",
              hint: "Select Mapping",
              semanticId: "mapping",
              items: SplMapping.values,
              value: panelData.relative ? SplMapping.relative : SplMapping.absolute,
              itemLabelBuilder: (SplMapping mapping) => mapping.displayName,
              onChanged: (SplMapping value) {
                context.read<SplViewModel>().updatePanelData(panelData.copyWith(relativeDb: value == SplMapping.relative));
              },
            ),
            if (panelData.relative)
              FusionOutlinedDropdown<SplRelativeRange>(
                label: "Range",
                hint: "Select Range",
                semanticId: "range",
                items: SplRelativeRange.values,
                value: panelData.relativeRange,
                itemLabelBuilder: (SplRelativeRange range) => range.displayName,
                onChanged: (SplRelativeRange value) {
                  context.read<SplViewModel>().updatePanelData(panelData.copyWith(relativeRange: value));
                },
              )
            else
              const _AbsoluteSettings(),
          ],
        );
      },
    );
  }
}

class _AbsoluteSettings extends StatelessWidget {
  const _AbsoluteSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplViewModel, SplState>(
      builder: (BuildContext context, SplState state) {
        const double minDb = 36.0, maxDb = 132.0;
        return Column(
          spacing: 12,
          children: <Widget>[
            _NumberField(
              semanticsId: "upper_limit",
              value: state.panelData.splUpperDb,
              label: "Upper Limit (dB)",
              onSubmitted: (num value) {
                final double clampedValue = value.clamp(minDb, maxDb).toDouble();
                final double lowerLimit = state.panelData.splLowerDb;
                if (clampedValue < lowerLimit) {
                  context.read<SplViewModel>().updatePanelData(state.panelData.copyWith(splUpperDb: clampedValue, splLowerDb: clampedValue));
                  return;
                }
                context.read<SplViewModel>().updatePanelData(state.panelData.copyWith(splUpperDb: clampedValue));
              },
            ),
            _NumberField(
              semanticsId: "lower_limit",
              value: state.panelData.splLowerDb,
              label: "Lower Limit (dB)",
              onSubmitted: (num value) {
                final double clampedValue = value.clamp(minDb, maxDb).toDouble();
                final double upperLimit = state.panelData.splUpperDb;
                if (clampedValue > upperLimit) {
                  context.read<SplViewModel>().updatePanelData(state.panelData.copyWith(splLowerDb: clampedValue, splUpperDb: clampedValue));
                  return;
                }
                context.read<SplViewModel>().updatePanelData(state.panelData.copyWith(splLowerDb: clampedValue));
              },
            ),
            Row(
              spacing: 12,
              children: <Widget>[
                FusionCheckbox(
                  semanticId: "invert_color_check",
                  onChanged: () => context.read<SplViewModel>().updatePanelData(state.panelData.copyWith(splInvertColor: !state.panelData.splInvertColor)),
                  value: state.panelData.splInvertColor,
                ),
                FusionAppText(
                  semanticId: "invert_color_label",
                  text: "Invert Colors",
                  style: context.textTheme.l1Regular,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    super.key,
    required this.semanticsId,
    required this.value,
    required this.label,
    required this.onSubmitted,
  });
  final String semanticsId;
  final num value;
  final String label;
  final void Function(num value) onSubmitted;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  final TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    _controller.text = widget.value.toString();
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: FusionAppText(
            semanticId: "${widget.semanticsId}_label",
            text: widget.label,
            style: context.textTheme.l1Regular,
          ),
        ),
        Expanded(
          child: SizedBox(
            child: FusionTextFormField(
              title: "",
              isDense: true,
              semanticId: "${widget.semanticsId}_input",
              hintText: "",
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
              ],
              controller: _controller,
              onTapOutside: () {
                _controller.text = widget.value.toString();
              },

              onSubmitted: (String value) {
                final num? numValue = num.tryParse(value);
                if (numValue != null) {
                  widget.onSubmitted(numValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
