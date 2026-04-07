import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class SettingToggleTile extends StatelessWidget {
  final String title;
  final ValueNotifier<bool> onChanged;

  const SettingToggleTile({
    super.key,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ValueListenableBuilder<bool>(
            valueListenable: onChanged,
            builder: (context, mode, _) {
              return FusionSwitch(
                height: 30,
                width: 50,
                radiusFactor: 0.35,
                value: onChanged.value,
                onChanged: (bool value) {
                  onChanged.value = value;


                },
              );
            }
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.b3Regular!.copyWith(
              fontWeight: FontWeight.w400,
              color: context.colorScheme.textDisabled,
            ),
          ),
        ),
      ],
    );
  }
}