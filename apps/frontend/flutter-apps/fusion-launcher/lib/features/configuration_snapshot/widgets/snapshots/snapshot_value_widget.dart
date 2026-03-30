import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/snapshots/SnapshotsKeys.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/widgets/configuration_widgets/action_drop_down.dart';
import '../../viewModel/actions_viewmodel/config_snapshot_actions_viewmodel.dart';

class SnapshotValueWidget extends StatefulWidget {
  final String actionId;
  final SceneValue value;
  final ValueChanged<SceneValue> onChanged;
  final int? index;

  const SnapshotValueWidget({super.key, required this.value, required this.onChanged, required this.actionId, this.index});

  @override
  State<SnapshotValueWidget> createState() => _SnapshotValueWidgetState();
}

class _SnapshotValueWidgetState extends State<SnapshotValueWidget> {
  ConfigSnapshotActionsViewModel get _cubit => context.read<ConfigSnapshotActionsViewModel>();

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
              SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, '${FusionTestKeys.instance.actionlistpanelrowdataitemvalueicon}_${widget.index}'),
                label: isMute ? 'volume_off' : 'volume_up',
                child: FusionIcon.icon(
                  isMute ? Icons.volume_off : Icons.volume_up,
                  size: 20,
                  color: context.colorScheme.primaryWhite,
                ),
              ),
              const SizedBox(width: 8),
              FusionAppText(
                semanticId: '${FusionTestKeys.instance.actionlistpanelrowdataitemvaluetext}_${widget.index}',
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
                  trackHeight: 2,
                  thumbColor: context.colorScheme.primaryWhite,
                ),
                child: SemanticHelper.slider(
                  testId: SemanticHelper.createTestId(
                    SemanticTypes.slider,
                    '${FusionTestKeys.instance.actionlistpanelrowdataitemvalueslider}_${widget.index}',
                  ),
                  value: currentValue,
                  child: Slider(
                    value: currentValue,
                    padding: EdgeInsets.zero,
                    activeColor: context.colorScheme.elevation2,
                    inactiveColor: context.colorScheme.primaryWhite,
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
            ),

            const SizedBox(width: 16),

            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FusionAppText(
                semanticId: '${FusionTestKeys.instance.actionlistpanelrowdataitemvaluetext}_${widget.index}',
                text: currentValue.toStringAsFixed(0),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
              ),
            ),
          ],
        );

      ///  Dropdown → must read value.dropdownItems
      case SceneParamValueType.dropdownSingle:

        /// Check if label is valid before fetching items
        if (value.label.isEmpty) {
          return FusionAppText(semanticId: '${FusionTestKeys.instance.actionlistpanelrowdataitemvalueemty}_${widget.index}', text: 'No parameter selected');
        }

        print('Fetching dropdown items for actionId: ${widget.actionId}');

        final List<SceneValueDropdown> items = _cubit.getSceneValueDropdownItems(widget.actionId);

        /// Find selected value by matching the stored string value with item labels
        SceneValueDropdown? selectedValue;
        if (value.value != null && value.value!.isNotEmpty && items.isNotEmpty) {
          try {
            print('Finding selected value for: ${value.value}');
            selectedValue = items.firstWhere(
              (SceneValueDropdown item) => item.label == value.value || item.value == value.value,
            );
          } catch (e) {
            /// No exact match found, leave selectedValue as null
            selectedValue = null;
          }
        }

        /// Using FusionDropdown widget
        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(
            SemanticTypes.container,
            '${FusionTestKeys.instance.actionlistpanelrowdataitemvaluedropdown}_${widget.index}',
          ),
          // value: selectedValue!.label,
          child: FusionDropdown<SceneValueDropdown>(
            value: selectedValue,
            items: items,
            hint: "Select an option",
            display: (SceneValueDropdown e) => e.label,
            onChanged: (SceneValueDropdown? v) {
              final SceneValue updated = value.copyWith(value: v?.value);
              widget.onChanged(updated);
            },
          ),
        );

      /// Text Input (simple string)
      case SceneParamValueType.textInput:
        return SizedBox(
          height: 28,
          child: Transform.scale(
            alignment: Alignment.center,
            scale: 0.9,
            child: SemanticHelper.textInput(
              testId: SemanticHelper.createTestId(
                SemanticTypes.textInput,
                '${FusionTestKeys.instance.actionlistpanelrowdataitemvaluetextinput}_${widget.index}',
              ),
              value: value.value ?? "",
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
          ),
        );

      /// On/Off toggle → stored as "on" or "off"
      case SceneParamValueType.onOffButton:
        final bool isOn = value.value == "on";

        return FusionSwitch(
          semanticId: '${FusionTestKeys.instance.actionlistpanelrowdataitemvalueonoffswitch}_${widget.index}',
          value: isOn,
          height: 22,
          width: 36,
          onChanged: (bool v) {
            final SceneValue updated = value.copyWith(value: v ? "on" : "off");
            widget.onChanged(updated);
          },
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
            FusionSwitch(
              semanticId: '${FusionTestKeys.instance.actionlistpanelrowdataitemvalueenableswitch}_${widget.index}',
              value: isEnabled,
              height: 22,
              width: 36,
              onChanged: (bool val) {
                final String newValue = "${val ? 'true' : 'false'}:$duration";
                print("new vwaluw = = > $newValue");

                final SceneValue updated = value.copyWith(value: newValue);
                widget.onChanged(updated);
              },
            ),

            const SizedBox(width: 8),

            /// Duration Input Field
            Expanded(
              child: SizedBox(
                height: 28,
                child: Transform.scale(
                  alignment: Alignment.center,
                  scale: 0.9,
                  child: SemanticHelper.textInput(
                    testId: SemanticHelper.createTestId(
                      SemanticTypes.textInput,
                      '${FusionTestKeys.instance.actionlistpanelrowdataitemvaluetextinputduration}_${widget.index}',
                    ),
                    child: TextFormField(
                      initialValue: duration,
                      // enabled: isEnabled,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                        counterText: '',
                        fillColor: context.colorScheme.elevation2,
                        filled: true,
                        labelStyle: context.textTheme.bodySmall,
                        labelText: "Duration (ms)",

                        border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                      ), // decoration: InputDecoration(
                      //   border: OutlineInputBorder(borderSide: BorderSide(color: context.colorScheme.elevation1)),
                      //   isDense: true,
                      //   labelText: "Duration (ms)",
                      //   labelStyle: context.textTheme.bodySmall,
                      //   contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      // ),
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
            ),
          ],
        );
    }
  }
}
