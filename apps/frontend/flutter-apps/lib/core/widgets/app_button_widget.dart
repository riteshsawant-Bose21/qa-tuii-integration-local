import 'package:flutter/material.dart';
import 'package:fusion_design_tool_prototype/core/theme/app_theme.dart';

import 'app_text_view.dart';

class AppButton extends StatefulWidget {
  final Function() onTap;
  final String buttonLabel;
  final String? buttonSubLabel;
  final ButtonStyle? buttonStyle;
  final Color? buttonColor;
  final FocusNode? focusNode;
  final TextStyle? labelStyle;
  final TextStyle? subLabelStyle;
  final Widget? child;
  final bool isEnabled;
  final Color? textColor; // Added textColor parameter
  final String? accessIdentifier;
  final String? accessLabel;
  final double? btnHeight;
  final double? btnWidth;

  const AppButton({
    super.key,
    required this.onTap,
    required this.buttonLabel,
    this.buttonStyle,
    this.buttonColor,
    this.focusNode,
    this.labelStyle,
    this.child,
    this.isEnabled = true,
    this.textColor, // Added textColor parameter
    this.accessIdentifier,
    this.accessLabel,
    this.btnHeight,
    this.btnWidth,
    this.buttonSubLabel,
    this.subLabelStyle, // Default to true if not specified
  });

  @override
  State createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return Center(
      child: SizedBox(
        height: widget.btnHeight ?? ((widget.buttonSubLabel != null) ? 60.0 : 50.0),
        width: widget.btnWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: width * 0.90, height: height * 0.058),
          child: Semantics(
            container: true,
            identifier: widget.accessIdentifier ?? widget.buttonLabel,
            label: widget.accessLabel ?? widget.buttonLabel,
            child: ExcludeSemantics(
              excluding: true,
              child: ElevatedButton(
                focusNode: widget.focusNode,
                onPressed: widget.isEnabled ? widget.onTap : null,
                style: widget.buttonStyle ??
                    ElevatedButton.styleFrom(
                      backgroundColor: widget.isEnabled ? widget.buttonColor ?? Theme.of(context).colorScheme.black : Theme.of(context).colorScheme.grey,
                    ),
                child: widget.child ??
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        AppTextView(
                          text: widget.buttonLabel,
                          style: widget.labelStyle ??
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: widget.isEnabled ? (widget.textColor ?? Theme.of(context).colorScheme.white) : Theme.of(context).colorScheme.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                        ),
                        if (widget.buttonSubLabel != null) ...<Widget>[
                          AppTextView(
                            text: widget.buttonSubLabel,
                            style: widget.subLabelStyle ??
                                Theme.of(context).textTheme.labelMedium!.copyWith(
                                      color: widget.isEnabled ? (widget.textColor ?? Theme.of(context).colorScheme.white) : Theme.of(context).colorScheme.grey,
                                      fontWeight: FontWeight.w200,
                                      fontSize: 12,
                                    ),
                          ),
                        ],
                      ],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
