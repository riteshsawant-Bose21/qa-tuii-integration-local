import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/text_field.dart';
import 'package:fusion_lib/fusion_lib.dart';

class InfoField extends StatelessWidget {
  final String label;
  final String? hint;
  final int maxLines;
  final TextEditingController controller;
  final Function? onChanges;
  final bool obscureText;

  const InfoField({
    required this.label,
    required this.controller,
    this.obscureText=false,
    this.onChanges,
    this.hint,
    this.maxLines = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:Theme.of(context).textTheme.l1Medium!.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colorScheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          AppTextField(controller: controller,
            maxLines: maxLines,
            obscureText: obscureText,
            onChanges: onChanges,
            hint: hint,
          ),
        ],
      ),
    );
  }


}
