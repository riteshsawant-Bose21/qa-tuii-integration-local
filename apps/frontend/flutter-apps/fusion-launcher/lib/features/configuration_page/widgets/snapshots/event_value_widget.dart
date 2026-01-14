import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'action_drop_down.dart';

class EventValueWidget extends StatefulWidget {
  final String actionId;
  final SceneValue value;
  final ValueChanged<SceneValue> onChanged;
  final EventStateTypes stateType;

  const EventValueWidget({
    super.key,
    required this.value,
    required this.onChanged,
    required this.actionId,
    required this.stateType,
  });

  @override
  State<EventValueWidget> createState() => _EventValueWidgetState();
}

class _EventValueWidgetState extends State<EventValueWidget> {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  Widget build(BuildContext context) {
    final SceneValue value = widget.value;

    switch (value.valueType) {
      /// Mute / Unmute (stored as "mute" or "unmute")
      case SceneParamValueType.muteUnmute:
        final String? currentStateValue = value.getValue(stateType: widget.stateType);
        final bool isMute = currentStateValue == "mute";

        return GestureDetector(
          onTap: () {
            final String newValue = isMute ? "unmute" : "mute";
            SceneValue updated;

            if (value.hasStates) {
              /// If this is the first time setting a state value and states are empty,
              /// initialize with appropriate defaults
              if (value.states == null) {
                /// Initialize both states with different defaults
                /// Above state gets "unmute", Below state gets "mute" by default
                /// The current state gets the new value the user is setting
                final String value1 = widget.stateType == EventStateTypes.above ? newValue : "unmute";
                final String value2 = widget.stateType == EventStateTypes.below ? newValue : "mute";

                updated = value.copyWith(
                  hasStates: true,
                  states: SceneStateValue(
                    value1: value1,
                    value2: value2,
                  ),
                );
              } else {
                updated = value.updateStateValue(newValue: newValue, stateType: widget.stateType);
              }
            } else {
              updated = value.copyWith(value: newValue);
            }

            widget.onChanged(updated);
          },
          child: Row(
            children: <Widget>[
              Icon(
                isMute ? Icons.volume_off : Icons.volume_up,
                size: 20,
                color: Theme.of(context).colorScheme.greyDark,
              ),
              const SizedBox(width: 8),
              FusionAppText(
                text: isMute ? "Mute" : "Unmute",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );

      /// Volume Slider → store number as string
      case SceneParamValueType.volumeSlider:
        final double currentValue = double.tryParse(value.getValue(stateType: widget.stateType) ?? "50") ?? 50;

        return Row(
          children: <Widget>[
            Flexible(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 4),
                  trackHeight: 1,
                  thumbColor: Theme.of(context).colorScheme.greyDark,
                ),
                child: Slider(
                  value: currentValue,
                  padding: EdgeInsets.zero,
                  activeColor: Theme.of(context).colorScheme.greyDark,
                  inactiveColor: Theme.of(context).colorScheme.grey,
                  min: 0,
                  max: 100,
                  divisions: 100,

                  label: currentValue.toStringAsFixed(0),
                  onChanged: (double v) {
                    SceneValue updated;

                    if (value.hasStates) {
                      /// If this is the first time setting a state value and states are empty,
                      /// initialize with appropriate defaults
                      if (value.states == null) {
                        /// Above state gets higher volume (80), Below state gets lower volume (20) by default
                        /// The current state gets the new value the user is setting
                        final String value1 = widget.stateType == EventStateTypes.above ? v.toString() : "80";
                        final String value2 = widget.stateType == EventStateTypes.below ? v.toString() : "20";

                        updated = value.copyWith(
                          hasStates: true,
                          states: SceneStateValue(
                            value1: value1,
                            value2: value2,
                          ),
                        );
                      } else {
                        updated = value.updateStateValue(newValue: v.toString(), stateType: widget.stateType);
                      }
                    } else {
                      updated = value.copyWith(value: v.toString());
                    }

                    widget.onChanged(updated);
                  },
                ),
              ),
            ),

            const SizedBox(width: 16),

            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FusionAppText(text: currentValue.toStringAsFixed(0), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9)),
            ),
          ],
        );

      ///  Dropdown → must read value.dropdownItems
      case SceneParamValueType.dropdownSingle:

        /// Check if label is valid before fetching items
        if (value.label.isEmpty) {
          return const Text('No parameter selected');
        }

        final List<SceneValueDropdown> items = _projectViewModel.getSceneValueDropdownItems(widget.actionId);

        /// Find selected value by matching the stored string value with item labels
        SceneValueDropdown? selectedValue;
        final String? currentStateValue = value.getValue(stateType: widget.stateType);
        if (currentStateValue != null && currentStateValue.isNotEmpty && items.isNotEmpty) {
          try {
            selectedValue = items.firstWhere(
              (SceneValueDropdown item) => item.label == currentStateValue || item.value == currentStateValue,
            );
          } catch (e) {
            /// No exact match found, leave selectedValue as null
            selectedValue = null;
          }
        }

        /// Using FusionDropdown widget
        return FusionDropdown<SceneValueDropdown>(
          value: selectedValue,
          items: items,
          hint: "Select an option",
          display: (SceneValueDropdown e) => e.label,
          onChanged: (SceneValueDropdown? v) {
            final String newValue = v?.label ?? v?.value ?? '';
            SceneValue updated;

            if (value.hasStates) {
              // If this is the first time setting a state value and states are empty,
              // initialize with appropriate defaults
              if (value.states == null) {
                // Above state gets first item, Below state gets second item by default
                // The current state gets the new value the user is setting
                final String value1 = widget.stateType == EventStateTypes.above ? newValue : (items.isNotEmpty ? items[0].label : '');
                final String value2 = widget.stateType == EventStateTypes.below ? newValue : (items.length > 1 ? items[1].label : '');

                updated = value.copyWith(
                  hasStates: true,
                  states: SceneStateValue(
                    value1: value1,
                    value2: value2,
                  ),
                );
              } else {
                updated = value.updateStateValue(newValue: newValue, stateType: widget.stateType);
              }
            } else {
              updated = value.copyWith(value: newValue);
            }

            widget.onChanged(updated);
          },
        );

      /// Text Input (simple string)
      case SceneParamValueType.textInput:
        return SizedBox(
          height: 28,
          child: Transform.scale(
            alignment: Alignment.center,
            scale: 0.9,
            child: TextFormField(
              initialValue: value.getValue(stateType: widget.stateType) ?? "",
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (String v) {
                SceneValue updated;

                if (value.hasStates) {
                  // If this is the first time setting a state value and states are empty,
                  // initialize with appropriate defaults
                  if (value.states == null) {
                    // Above state gets "Above Value", Below state gets "Below Value" by default
                    // The current state gets the new value the user is setting
                    final String value1 = widget.stateType == EventStateTypes.above ? v : "Above Value";
                    final String value2 = widget.stateType == EventStateTypes.below ? v : "Below Value";

                    updated = value.copyWith(
                      hasStates: true,
                      states: SceneStateValue(
                        value1: value1,
                        value2: value2,
                      ),
                    );
                  } else {
                    updated = value.updateStateValue(newValue: v, stateType: widget.stateType);
                  }
                } else {
                  updated = value.copyWith(value: v);
                }

                widget.onChanged(updated);
              },
            ),
          ),
        );

      /// On/Off toggle → stored as "on" or "off"
      case SceneParamValueType.onOffButton:
        final bool isOn = value.getValue(stateType: widget.stateType) == "on";

        return SizedBox(
          height: 12,
          child: Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isOn,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              thumbColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Theme.of(context).colorScheme.white;
                }
                return Theme.of(context).colorScheme.greyDark;
              }),
              trackColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Theme.of(context).colorScheme.black;
                }
                return Theme.of(context).colorScheme.grey;
              }),
              trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
              onChanged: (bool v) {
                final String newValue = v ? "on" : "off";
                SceneValue updated;

                if (value.hasStates) {
                  // If this is the first time setting a state value and states are empty,
                  // initialize with appropriate defaults
                  if (value.states == null) {
                    // Above state gets "on", Below state gets "off" by default
                    // The current state gets the new value the user is setting
                    final String value1 = widget.stateType == EventStateTypes.above ? newValue : "on";
                    final String value2 = widget.stateType == EventStateTypes.below ? newValue : "off";

                    updated = value.copyWith(
                      hasStates: true,
                      states: SceneStateValue(
                        value1: value1,
                        value2: value2,
                      ),
                    );
                  } else {
                    updated = value.updateStateValue(newValue: newValue, stateType: widget.stateType);
                  }
                } else {
                  updated = value.copyWith(value: newValue);
                }

                widget.onChanged(updated);
              },
            ),
          ),
        );

      case SceneParamValueType.pulse:

        /// Parse the pulse value format: "enabled:duration" or fallback to defaults
        final String pulseValue = value.value ?? "false:0";
        final List<String> parts = pulseValue.split(':');
        final bool isEnabled = parts.isNotEmpty && parts[0] == 'true';
        final String duration = parts.length > 1 ? parts[1] : "0";

        return Row(
          children: <Widget>[
            /// Enable/Disable Switch
            SizedBox(
              height: 12,
              child: Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isEnabled,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  thumbColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return Theme.of(context).colorScheme.white;
                    }
                    return Theme.of(context).colorScheme.greyDark;
                  }),
                  trackColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return Theme.of(context).colorScheme.greyDark;
                    }
                    return Theme.of(context).colorScheme.grey;
                  }),
                  trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                  onChanged: (bool val) {
                    final String newValue = "${val ? 'true' : 'false'}:$duration";
                    print("new vwaluw = = > $newValue");

                    final SceneValue updated = value.copyWith(value: newValue);
                    widget.onChanged(updated);
                    setState(() {});
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),

            /// Duration Input Field
            Expanded(
              child: SizedBox(
                height: 28,
                child: Transform.scale(
                  alignment: Alignment.center,
                  scale: 0.9,
                  child: TextFormField(
                    initialValue: duration,
                    // enabled: isEnabled,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderSide: BorderSide(color: context.colorScheme.dividerColor)),
                      isDense: true,
                      labelText: "Duration (ms)",
                      labelStyle: const TextStyle(fontSize: 10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onChanged: (String v) {
                      /// Ensure only valid numbers are accepted
                      final String sanitizedValue = v.replaceAll(RegExp(r'[^0-9]'), '');
                      final String newValue = "${isEnabled ? 'true' : 'false'}:$sanitizedValue";
                      print("new vwaluw = = > $newValue");
                      final SceneValue updated = value.copyWith(value: newValue);
                      widget.onChanged(updated);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
