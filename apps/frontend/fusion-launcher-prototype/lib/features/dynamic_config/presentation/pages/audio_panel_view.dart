import 'package:flutter/material.dart';

import '../../../../core/service_locator.dart';
import '../../domain/entities/audio_widget_entity.dart';
import '../../domain/entities/audio_widget_value.dart';
import '../../domain/entities/panel_entity.dart';
import '../bloc/panel_bloc.dart';
import '../bloc/panel_bloc_event.dart';
import '../widgets/audio_gain_fader_widget.dart';
import '../widgets/audio_meter_widget.dart';
import '../widgets/audio_toggle_button_widget.dart';

class AudioPanelView extends StatelessWidget {
  final PanelEntity panel;
  const AudioPanelView({super.key, required this.panel});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Builder(
        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
                child: Wrap(
                  spacing: 16.0,
                  runSpacing: 16.0,
                  runAlignment: WrapAlignment.start,
                  alignment: WrapAlignment.start,
                  children: <Widget>[
                    _buildToggleButtons(panel.getButtons(), AudioWidgetType.toggleButton, context),
                    _buildMetersFaders(panel.getMeters(), AudioWidgetType.meter, context),
                    _buildMetersFaders(panel.getFaders(), AudioWidgetType.gainFader, context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetersFaders(List<AudioWidgetEntity> widgetsList, AudioWidgetType widgetType, BuildContext context) {
    if (widgetsList.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 24,
            child: Row(
              spacing: 8.0,
              children: <Widget>[
                widgetType == AudioWidgetType.gainFader
                    ? const RotatedBox(
                      quarterTurns: 1,
                      child: Icon(
                        Icons.tune,
                        size: 24,
                      ),
                    )
                    : const Icon(
                      Icons.equalizer,
                      size: 24,
                    ),
                Text(
                  widgetType == AudioWidgetType.meter ? "Meters" : "Faders",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Divider(),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 32,
              runSpacing: 32,
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              children:
                  widgetsList.map((AudioWidgetEntity audioWidgetEntity) {
                    final dynamic widgetValue = audioWidgetEntity.value.value;
                    final String widgetName = audioWidgetEntity.name;
                    return Builder(
                      builder: (BuildContext context) {
                        if (widgetType == AudioWidgetType.gainFader) {
                          return AudioGainFader(
                            height: 284,
                            width: 80,
                            name: widgetName.toUpperCase(),
                            minValue:
                                (audioWidgetEntity.minValue!.value is double)
                                    ? audioWidgetEntity.minValue?.value
                                    : (double.tryParse(audioWidgetEntity.minValue!.value.toString()) ?? 0.0),
                            maxValue:
                                (audioWidgetEntity.maxValue!.value is double)
                                    ? audioWidgetEntity.maxValue!.value
                                    : (double.tryParse(audioWidgetEntity.maxValue!.value.toString()) ?? 100.0),
                            orientation: audioWidgetEntity.audioWidgetOrientation,
                            currentValue: (widgetValue is double) ? widgetValue : (double.tryParse(widgetValue.toString()) ?? 0.0),
                            onChanged: (double value) {
                              serviceLocator<PanelBloc>().add(
                                UpdateServerWithAudioWidgetValue(
                                  AudioWidgetValue.from(value, AudioWidgetValue.floatValue),
                                  audioWidgetEntity,
                                ),
                              );
                            },
                          );
                        } else {
                          return AudioMeter(
                            height: 284,
                            width: 80,
                            name: widgetName.toUpperCase(),
                            orientation: audioWidgetEntity.audioWidgetOrientation,
                            minValue:
                                (audioWidgetEntity.minValue!.value is double)
                                    ? audioWidgetEntity.minValue!.value
                                    : (double.tryParse(audioWidgetEntity.minValue.toString()) ?? 0.0),
                            maxValue:
                                (audioWidgetEntity.maxValue!.value is double)
                                    ? audioWidgetEntity.maxValue!.value
                                    : (double.tryParse(audioWidgetEntity.maxValue!.value.toString()) ?? 100.0),
                            currentValue: (widgetValue is double) ? widgetValue : (double.tryParse(widgetValue.toString()) ?? 0.0),
                          );
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons(List<AudioWidgetEntity> widgetsList, AudioWidgetType widgetType, BuildContext context) {
    if (widgetsList.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Wrap(
        // mainAxisSize: MainAxisSize.min,
        alignment: WrapAlignment.start,
        direction: Axis.horizontal,
        children: <Widget>[
          const Align(
            alignment: Alignment.center,
            child: SizedBox(
              height: 24,
              child: Row(
                spacing: 8.0,
                children: <Widget>[
                  Icon(
                    Icons.toggle_on_outlined,
                    size: 24,
                  ),
                  Text(
                    "Buttons",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Divider(),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children:
                  widgetsList.map((AudioWidgetEntity widgetModel) {
                    final bool widgetValue = widgetModel.value.value;
                    final String widgetName = widgetModel.name;
                    return SizedBox(
                      height: 44,
                      width: 120,
                      child: AudioToggleButtonWidget(
                        initialToggleState: widgetValue,
                        name: widgetName.toUpperCase(),
                        onToggle: (bool isToggled) {
                          serviceLocator<PanelBloc>().add(
                            UpdateServerWithAudioWidgetValue(
                              AudioWidgetValue.from(isToggled, AudioWidgetValue.boolValue),
                              widgetModel,
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
