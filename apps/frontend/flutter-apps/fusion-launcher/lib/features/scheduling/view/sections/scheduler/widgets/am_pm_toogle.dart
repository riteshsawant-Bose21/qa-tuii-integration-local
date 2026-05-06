import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class AmPmToggle extends StatefulWidget {
  const AmPmToggle({
    required this.isAM,
    required this.borderColor,
    required this.onChanged,
  });

  final bool isAM;
  final Color borderColor;
  final ValueChanged<bool> onChanged; // true = AM, false = PM

  @override
  State<AmPmToggle> createState() => AmPmToggleState();
}

class AmPmToggleState extends State<AmPmToggle> {
  bool _hoverAM = false;
  bool _hoverPM = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height: 42,
          width: 38,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: context.colorScheme.elevation2,
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: <Widget>[
              Expanded(
                child: _buildHalf(
                  context: context,
                  label: "AM",
                  selected: widget.isAM,
                  hovering: _hoverAM,
                  onHover: (bool v) => setState(() => _hoverAM = v),
                  onTap: () => widget.onChanged(true),
                  accent: context.colorScheme.strokeLight,
                ),
              ),
              Expanded(
                child: _buildHalf(
                  context: context,
                  label: "PM",
                  selected: !widget.isAM,
                  hovering: _hoverPM,
                  onHover: (bool v) => setState(() => _hoverPM = v),
                  onTap: () => widget.onChanged(false),
                  accent: context.colorScheme.strokeLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildHalf({
    required BuildContext context,
    required String label,
    required bool selected,
    required bool hovering,
    required ValueChanged<bool> onHover,
    required VoidCallback onTap,
    required Color accent,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected
                    ? context.colorScheme.elevation3
                    : hovering
                    ? accent
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FusionAppText(
            semanticId: 'timing_section_am_pm_toggle_label',
            text: label,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: (selected || hovering) ? context.colorScheme.textPrimary : context.colorScheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
