import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../authentication/launcher_sign_in_page.dart';

class PasscodeInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? hintText;

  const PasscodeInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<PasscodeInputField> createState() => _PasscodeInputFieldState();
}

class _PasscodeInputFieldState extends State<PasscodeInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 300,
      alignment: Alignment.centerLeft,
      child: NeumorphicDarkTextField(
        controller: widget.controller,
        enabled: widget.enabled,
        isObscured: _obscureText,
        borderRadius: 6,
        hintStyle: context.textTheme.labelMedium!.copyWith(
          color: widget.enabled ? context.colorScheme.textPrimary : context.colorScheme.textDisabled,
        ),
        suffix: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 16,
              color: context.colorScheme.textDisabled,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
      ),
    );
  }
}
