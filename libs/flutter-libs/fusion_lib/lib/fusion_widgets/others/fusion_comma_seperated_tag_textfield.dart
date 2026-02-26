import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../text_views/fusion_app_text.dart';

class FusionCommaSeperatedTagTextfield extends StatefulWidget {
  final List<String> values;
  final String label;
  final String hintText;
  final ValueChanged<List<String>> onChanged;

  const FusionCommaSeperatedTagTextfield({
    super.key,
    required this.values,
    required this.label,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<FusionCommaSeperatedTagTextfield> createState() => _FusionCommaSeperatedTagTextfieldState();
}

class _FusionCommaSeperatedTagTextfieldState extends State<FusionCommaSeperatedTagTextfield> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late List<String> tags;

  @override
  void initState() {
    super.initState();
    tags = <String>[...widget.values];
  }

  @override
  void didUpdateWidget(covariant FusionCommaSeperatedTagTextfield oldWidget) {
    super.didUpdateWidget(oldWidget);
    tags = <String>[...widget.values];
  }

  void _commitTag() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      tags.add(text);
      _controller.clear();
    });

    widget.onChanged(tags);
  }

  @override
  Widget build(BuildContext context) {
    const double radius = 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: widget.label,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colorScheme.textPrimary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: _focusNode.hasFocus ? context.colorScheme.primaryWhite : context.colorScheme.strokeLight,
              ),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ...tags.map(
                  (String tag) => ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Chip(
                      side: BorderSide.none,
                      backgroundColor: context.colorScheme.elevation3,
                      padding: const EdgeInsets.all(10),
                      label: FusionAppText(
                        text: tag,
                        style: context.textTheme.labelMedium,
                      ),
                      onDeleted: () {
                        setState(() => tags.remove(tag));
                        widget.onChanged(tags);
                      },
                    ),
                  ),
                ),
                TextFormField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: context.textTheme.labelLarge?.copyWith(color: context.colorScheme.textPrimary.withValues(alpha: 0.4)),
                    errorStyle: context.textTheme.labelLarge?.copyWith(color: context.colorScheme.errorText),
                    isDense: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                  ),
                  onFieldSubmitted: (_) => _commitTag(),
                  onChanged: (String value) {
                    if (value.endsWith(',')) {
                      _controller.text = value.replaceAll(',', '');
                      _commitTag();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
