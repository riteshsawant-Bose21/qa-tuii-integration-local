import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_checkbox.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class FusionRadioChipSelector<T> extends StatelessWidget {
  final T? selected;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onChanged;
  final double spacing;

  const FusionRadioChipSelector({
    super.key,
    required this.selected,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < options.length; i++) ...<Widget>[
          Expanded(
            child: _RadioChip(
              label: labelBuilder(options[i]),
              isSelected: selected == options[i],
              onTap: () => onChanged(options[i]),
            ),
          ),
          if (i < options.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// An outlined chip with a radio circle on the left.
class _RadioChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RadioChip> createState() => _RadioChipState();
}

class _RadioChipState extends State<_RadioChip> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: (widget.isSelected || hovered) ? context.colorScheme.elevation2 : context.colorScheme.elevation1,
            border: Border.all(
              color: widget.isSelected ? Colors.transparent : context.colorScheme.strokeLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FusionCheckbox(
                innerChild: Icon(
                  Icons.check,
                  size: 10,
                  color: widget.isSelected ? context.colorScheme.black : null,
                ),
                value: widget.isSelected,
                shape: BoxShape.circle,
                onChanged: widget.onTap,
                semanticId: '',
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FusionAppText(
                  text: widget.label,
                  maxLine: 1,
                  style: context.textTheme.b3Medium.copyWith(
                    color: widget.isSelected ? context.colorScheme.textPrimary : context.colorScheme.textBody,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
