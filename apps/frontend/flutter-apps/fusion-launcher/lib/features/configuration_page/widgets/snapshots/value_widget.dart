import 'package:flutter/material.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_model.dart';

class ValueWidgetForRow extends StatefulWidget {
  final SceneValue value;
  final ValueChanged<SceneValue> onChanged;

  const ValueWidgetForRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ValueWidgetForRow> createState() => _ValueWidgetForRowState();
}

class _ValueWidgetForRowState extends State<ValueWidgetForRow> {
  @override
  Widget build(BuildContext context) {
    final SceneValue value = widget.value;

    switch (value.valueType) {
      // ---------------------------------------------------
      // 1️⃣ Mute / Unmute (stored as "mute" or "unmute")
      // ---------------------------------------------------
      case SceneParamValueType.muteUnmute:
        final bool isMute = value.value == "mute";

        return Row(
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final SceneValue updated = value.copyWith(value: "mute");
                  widget.onChanged(updated);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMute ? Colors.red : null,
                ),
                child: const Text("Mute"),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final SceneValue updated = value.copyWith(value: "unmute");
                  widget.onChanged(updated);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: !isMute ? Colors.green : null,
                ),
                child: const Text("Unmute"),
              ),
            ),
          ],
        );

      // ---------------------------------------------------
      // 2️⃣ Volume Slider → store number as string
      // ---------------------------------------------------
      case SceneParamValueType.volumeSlider:
        final double currentValue = double.tryParse(value.value ?? "50") ?? 50;

        return Slider(
          value: currentValue,
          min: 0,
          max: 100,
          divisions: 100,
          label: currentValue.toStringAsFixed(0),
          onChanged: (double v) {
            final SceneValue updated = value.copyWith(value: v.toString());
            widget.onChanged(updated);
            setState(() {});
          },
        );

      // ---------------------------------------------------
      // 3️⃣ Dropdown → must read value.dropdownItems
      // ---------------------------------------------------
      case SceneParamValueType.dropdownSingle:
        final items = value.dropdownItems ?? <dynamic>[];

        return DropdownButtonFormField<String>(
          value: value.value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items:
              items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
          onChanged: (String? selected) {
            final SceneValue updated = value.copyWith(value: selected);
            widget.onChanged(updated);
            setState(() {});
          },
        );

      // ---------------------------------------------------
      // 4️⃣ Text Input (simple string)
      // ---------------------------------------------------
      case SceneParamValueType.textInput:
        return TextFormField(
          initialValue: value.value ?? "",
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (String v) {
            final SceneValue updated = value.copyWith(value: v);
            widget.onChanged(updated);
          },
        );

      // ---------------------------------------------------
      // 5️⃣ On/Off toggle → stored as "on" or "off"
      // ---------------------------------------------------
      case SceneParamValueType.onOffButton:
        final bool isOn = value.value == "on";

        return Switch(
          value: isOn,
          onChanged: (bool v) {
            final SceneValue updated = value.copyWith(value: v ? "on" : "off");
            widget.onChanged(updated);
            setState(() {});
          },
        );

      // ---------------------------------------------------
      // fallback
      // ---------------------------------------------------
      default:
        return const SizedBox.shrink();
    }
  }
}
