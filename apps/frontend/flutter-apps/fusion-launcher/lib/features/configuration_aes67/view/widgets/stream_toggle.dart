import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

/// Toggle switch styled to match the green pill in the screenshot
class StreamToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const StreamToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.75,
      child: SemanticHelper.toggle(
        value: value,
        testId: SemanticHelper.createTestId(SemanticTypes.toggle, 'aes67_stream_toggle'),
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: context.colorScheme.primaryColor,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: context.colorScheme.strokeLight,
        ),
      ),
    );
  }
}
