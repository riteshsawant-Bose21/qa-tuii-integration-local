import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';

class AppTextView extends StatefulWidget {
  const AppTextView({
    super.key,
    this.fontSize = 14,
    this.style,
    required this.text,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
    this.accessIdentifier,
    this.accessLabel,
  });

  final double fontSize;
  final TextStyle? style;
  final String? text;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? accessIdentifier;
  final String? accessLabel;

  @override
  State<AppTextView> createState() => _AppTextViewState();
}

class _AppTextViewState extends State<AppTextView> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        //to handle the responsive sizes we can change the font sizes here based on the screen width
        //
        return SemanticHelper.staticText(
          testId: SemanticHelper.createTestId(SemanticTypes.text, (widget.accessIdentifier ?? widget.text)!),
          child: Text(
            widget.text ?? "",
            textAlign: widget.textAlign,
            style: widget.style ?? Theme.of(context).textTheme.labelMedium,
            maxLines: widget.maxLines,
            overflow: widget.overflow ?? ((widget.maxLines != null) ? TextOverflow.ellipsis : null),
          ),
        );
      },
    );
  }
}
