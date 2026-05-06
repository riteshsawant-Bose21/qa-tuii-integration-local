import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_svg_icon.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:intl/intl.dart';

enum DateFieldTarget { single, from, to }

class DateFieldBox extends StatefulWidget {
  const DateFieldBox({
    required this.target,
    required this.selectedDate,
    required this.onTap,
    this.hasError = false,
    this.isOpen = false,
    required this.semanticId,
  });

  final DateFieldTarget target;
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final bool hasError;
  final bool isOpen;
  final String semanticId;

  @override
  State<DateFieldBox> createState() => DateFieldBoxState();
}

class DateFieldBoxState extends State<DateFieldBox> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "scheduler_form_timing_section_${widget.semanticId}_date_input_field",
      ),
      value: widget.selectedDate.toString(),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: (widget.isOpen || _isHovering) ? context.colorScheme.elevation2 : Colors.transparent,
              border: Border.all(
                color: widget.isOpen ? Colors.transparent : context.colorScheme.strokeLight,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.selectedDate != null ? DateFormat('dd/MM/yyyy').format(widget.selectedDate!) : "dd/mm/yyyy",
                    style: context.textTheme.b3Regular.copyWith(
                      color: widget.selectedDate != null ? context.colorScheme.textPrimary : context.colorScheme.textBody,
                    ),
                  ),
                ),
                FusionIcon.icon(
                  semanticId: 'scheduler_form_timing_section_date_input_icon',
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: context.colorScheme.iconDefault,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
