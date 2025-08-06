import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_design_tool_prototype/core/theme/app_theme.dart';

import 'app_text_view.dart';

class AppTextField extends StatefulWidget {
  final String title;
  final FormFieldValidator<String>? validator;
  final String? value;
  final ValueChanged<String>? onValueChange;
  final ValueChanged<String>? onSubmit;
  final bool multiline;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Function()? onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;

  final bool enabled;

  final bool autoFocus;
  final bool obscureText;
  final Widget? suffixIcon;
  final AutovalidateMode? autoValidate;
  final TextStyle? labelStyle;
  final bool showWithoutPadding;
  final bool showWithoutLabel;

  const AppTextField({
    super.key,
    required this.title,
    this.validator,
    this.value,
    required this.onValueChange,
    this.multiline = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onTap,
    this.controller,
    this.focusNode,
    this.onSubmit,
    this.enabled = true,
    this.autoFocus = false,
    this.suffixIcon,
    this.obscureText = false,
    this.autoValidate,
    this.labelStyle,
    this.hintText,
    this.showWithoutPadding = false,
    this.showWithoutLabel = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!widget.showWithoutLabel) ...<Widget>[
            Row(
              children: <Widget>[
                const SizedBox(
                  width: 15,
                ),
                AppTextView(
                  text: widget.title,
                  style: widget.labelStyle ??
                      Theme.of(context).textTheme.labelMedium!.copyWith(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.greyDark,
                            fontWeight: FontWeight.w400,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
          ],
          Container(
            // decoration: BoxDecoration(boxShadow: [
            //   BoxShadow(
            //     // color: Colors.pink.withValues(alpha:0.2),
            //     color: Theme.of(context).colorScheme.secondary.withAlpha(1),
            //     spreadRadius: 0.5,
            //     blurRadius: 30,
            //     offset: const Offset(0, 4),
            //   )
            // ]),
            padding: widget.showWithoutPadding ? null : const EdgeInsets.symmetric(horizontal: 15.0),
            child: TextFormField(
              autovalidateMode: widget.autoValidate,
              controller: widget.controller,
              autofocus: widget.autoFocus,
              enabled: widget.enabled,
              textInputAction: TextInputAction.done,
              keyboardType: widget.keyboardType,
              focusNode: widget.focusNode,
              validator: widget.validator,
              obscureText: widget.obscureText,
              initialValue: widget.value,
              decoration: InputDecoration(
                fillColor: Theme.of(context).colorScheme.softGrey.withValues(alpha: 0.8),
                filled: true,
                hintText: widget.hintText,
                suffixIcon: widget.suffixIcon,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32.0),
                  borderSide: const BorderSide(
                    width: 0,
                    style: BorderStyle.none,
                  ),
                ),
              ),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(fontSize: 16),
              onFieldSubmitted: widget.onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
