import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'action_drop_down.dart';

class ValueWidgetForRow extends StatefulWidget {
  final String actionId;
  final SceneValue value;
  final ValueChanged<SceneValue> onChanged;

  const ValueWidgetForRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.actionId,
  });

  @override
  State<ValueWidgetForRow> createState() => _ValueWidgetForRowState();
}

class _ValueWidgetForRowState extends State<ValueWidgetForRow> {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  Widget build(BuildContext context) {
    final SceneValue value = widget.value;

    switch (value.valueType) {
      /// Mute / Unmute (stored as "mute" or "unmute")
      case SceneParamValueType.muteUnmute:
        final bool isMute = value.value == "mute";

        return GestureDetector(
          onTap: () {
            final SceneValue updated = value.copyWith(value: isMute ? "unmute" : "mute");
            widget.onChanged(updated);
            setState(() {});
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
        final double currentValue = double.tryParse(value.value ?? "50") ?? 50;

        return Row(
          children: <Widget>[
            Flexible(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 4),
                  trackHeight: 1,
                  thumbColor: Theme.of(context).colorScheme.black,
                ),
                child: Slider(
                  value: currentValue,
                  padding: EdgeInsets.zero,
                  activeColor: Theme.of(context).colorScheme.black,
                  inactiveColor: Theme.of(context).colorScheme.grey,
                  min: 0,
                  max: 100,
                  divisions: 100,

                  label: currentValue.toStringAsFixed(0),
                  onChanged: (double v) {
                    final SceneValue updated = value.copyWith(value: v.toString());
                    widget.onChanged(updated);
                    setState(() {});
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
        if (value.value != null && value.value!.isNotEmpty && items.isNotEmpty) {
          try {
            selectedValue = items.firstWhere(
              (SceneValueDropdown item) => item.label == value.value || item.value == value.value,
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
            final SceneValue updated = value.copyWith(value: v?.label ?? v?.value);
            widget.onChanged(updated);
            setState(() {});
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
              initialValue: value.value ?? "",
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (String v) {
                final SceneValue updated = value.copyWith(value: v);
                widget.onChanged(updated);
              },
            ),
          ),
        );

      /// On/Off toggle → stored as "on" or "off"
      case SceneParamValueType.onOffButton:
        final bool isOn = value.value == "on";

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
                final SceneValue updated = value.copyWith(value: v ? "on" : "off");
                widget.onChanged(updated);
                setState(() {});
              },
            ),
          ),
        );
    }
  }
}
