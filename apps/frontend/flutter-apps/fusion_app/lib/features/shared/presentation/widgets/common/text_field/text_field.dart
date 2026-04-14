import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class AppTextField extends StatelessWidget {

  final String? hint;
  final int maxLines;
  final TextEditingController controller;
  final Function? onChanges;
  final bool obscureText;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Color? filledColor;
  final Color? borderColor;
  final FocusNode? focusNode;

  const AppTextField({
    required this.controller,
    this.obscureText=false,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanges,
    this.focusNode,
    this.enabled =true,
    this.hint,
    this.maxLines = 1,
    this.filledColor,
    this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      enabled: enabled,
      focusNode: focusNode,
      onChanged: (String data){
        if(onChanges!=null){
           onChanges!(data);
        }
      },
      style: Theme.of(context).textTheme.b3Regular!.copyWith(
        fontWeight: FontWeight.w400,
        color: context.colorScheme.textPrimary,
      ),
      cursorColor:context.colorScheme.textPrimary,
      decoration: _inputDecoration(hint,context),
    );
  }

  InputDecoration _inputDecoration(String? hint,BuildContext context) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: context.colorScheme.textPlaceholder,
      ),

      filled: true,
      fillColor: enabled ? getEnabledColor(context): context.colorScheme.elevation1,
      suffixIcon: suffixIcon ?? null,
      prefixIcon: prefixIcon ?? null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:  BorderSide(
          color:context.colorScheme.strokeLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:  BorderSide(
          color:  borderColor ?? context.colorScheme.primary,
        ),
      ),
    );
  }

 Color getEnabledColor(BuildContext context) {

    if(filledColor!=null){
      return filledColor!;
    }
    return context.colorScheme.primaryBlack;
  }
}
