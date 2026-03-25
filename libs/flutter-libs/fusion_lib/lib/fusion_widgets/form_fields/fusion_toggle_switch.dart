import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

/// A reusable toggle row widget with a switch and a label.
///
/// This widget is designed for Fusion-style settings rows.
/// It supports custom label text, switch state, and a callback for changes.
///
/// Example usage:
/// ```dart
/// FusionToggleRow(
///   title: "Enable Notifications",
///   value: true,
///   onChanged: (bool newValue) {
///     print("Switch is now: $newValue");
///   },
/// )
/// ```
class FusionToggleRow extends StatelessWidget {
  /// The text label shown next to the switch.
  final String title;

  /// Whether the switch is currently on or off.
  final bool value;

  /// Callback triggered when the switch value changes.
  final ValueChanged<bool> onChanged;

  final Color? activeColor;

  final Color? activeTrackColor;

  final Color? inactiveThumbColor;

  final Color? inactiveTrackColor;

  final String semanticId;

  /// Creates a Fusion toggle row.
  const FusionToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.semanticId,
    required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.toggle(
      testId: SemanticHelper.createTestId(
        SemanticTypes.toggle,
        'fusion_toggle_switch_$semanticId',
      ),
      value: value,
      child: Row(
        children: <Widget>[
          SizedBox(
            height: 18,
            width: 30,
            child: FittedBox(
              fit: BoxFit.cover,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: activeColor ?? context.colorScheme.primaryWhite,
                activeTrackColor:
                    activeTrackColor ?? context.colorScheme.primaryBlack,
                inactiveThumbColor:
                    inactiveThumbColor ?? context.colorScheme.primaryWhite,
                inactiveTrackColor:
                    inactiveTrackColor ?? const Color(0xFFE5E5E5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                splashRadius: 0,
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                thumbColor: WidgetStateProperty.all(
                  context.colorScheme.primaryWhite,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
