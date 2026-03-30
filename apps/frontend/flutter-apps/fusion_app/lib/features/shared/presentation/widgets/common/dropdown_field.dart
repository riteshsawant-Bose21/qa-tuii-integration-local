import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/text_field.dart';
import 'package:fusion_lib/fusion_lib.dart';

class CommonDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final bool enabled;
  final TextEditingController controller;

  const CommonDropdownField({super.key,
    required this.label,
    required this.controller,
    required this.hint,
     this.enabled=true,
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
            style:Theme.of(context).textTheme.l1Medium.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colorScheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: controller,
            maxLines: 1,
            enabled: false,
            hint: hint,
            onChanges: (){

            },
            suffixIcon: GestureDetector(
              onTap: (){
                controller.clear();
              },
              child: Icon(
                  Icons.keyboard_arrow_down_outlined,
                  color: context.colorScheme.textDisabled),
            ),

          ),
        ],
      ),
    );
  }
}
