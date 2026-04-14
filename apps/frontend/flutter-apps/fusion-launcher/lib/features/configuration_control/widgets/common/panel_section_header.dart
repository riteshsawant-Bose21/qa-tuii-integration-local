import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A shared panel/card section header widget used across all configuration-control
/// panels (zones list, virtual controller, virtual control, controller settings).
///
/// Renders an [elevation2] banner with rounded top corners (radius 12),
/// a bottom [strokeLight] divider, and the [title] in [l1Regular] / [textBody].
///
/// Usage:
/// ```dart
/// PanelSectionHeader(title: 'ZONES')
/// PanelSectionHeader(title: 'VIRTUAL CONTROLLER')
/// PanelSectionHeader(title: 'VIRTUAL CONTROL')
/// PanelSectionHeader(title: 'CONTROLLER SETTINGS')
/// ```
///
/// Pass [trailing] to add any action widgets (icons, buttons) on the right side.
class PanelSectionHeader extends StatelessWidget {
  final String title;

  /// Optional widget(s) shown on the trailing (right) side of the header.
  final Widget? trailing;

  const PanelSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: context.colorScheme.strokeLight, width: 1),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FusionAppText(
              text: title,
              style: Theme.of(context).textTheme.l1Regular.withColor(context.colorScheme.textBody),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
